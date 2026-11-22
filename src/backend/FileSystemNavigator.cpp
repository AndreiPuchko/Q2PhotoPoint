#include "FileSystemNavigator.h"

#include <QCryptographicHash>
#include <QDateTime>
#include <QDir>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonParseError>
#include <QSaveFile>
#include <QStorageInfo>
#include <QUrl>
#include <QVariantMap>

#include <string>

#ifdef Q_OS_WIN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#endif

FileSystemNavigator::FileSystemNavigator(QObject *parent)
    : QObject(parent)
{
}

QVariantList FileSystemNavigator::availableWindowsDrives() const
{
    QVariantList drives;

#ifdef Q_OS_WIN
    const QFileInfoList driveRoots = QDir::drives();
    for (const QFileInfo &driveRoot : driveRoots) {
        QStorageInfo storage(driveRoot.filePath());
        if (!storage.isValid() || !storage.isReady())
            continue;

        const QString rootPath = storage.rootPath().isEmpty()
            ? driveRoot.filePath()
            : storage.rootPath();
        QString displayRoot = QDir::toNativeSeparators(rootPath);
        if (displayRoot.endsWith(QDir::separator()))
            displayRoot.chop(1);

        const std::wstring nativeRoot = QDir::toNativeSeparators(rootPath).toStdWString();
        const bool isNetwork = GetDriveTypeW(nativeRoot.c_str()) == DRIVE_REMOTE;
        QString volumeName = storage.name().trimmed();
        if (volumeName.isEmpty())
            volumeName = isNetwork ? QStringLiteral("Network location") : QStringLiteral("Local Disk");

        QVariantMap drive;
        drive.insert(QStringLiteral("fileName"),
                     QStringLiteral("%1 (%2)").arg(volumeName, displayRoot));
        drive.insert(QStringLiteral("fileURL"), QUrl::fromLocalFile(rootPath).toString());
        drives.append(drive);
    }
#endif

    return drives;
}

QString FileSystemNavigator::imageStateHash(const QUrl &url) const
{
    const QFileInfo fileInfo(url.toLocalFile());
    QString path = fileInfo.exists()
        ? fileInfo.absoluteFilePath()
        : url.toString(QUrl::FullyEncoded);
#ifdef Q_OS_WIN
    path = path.toCaseFolded();
#endif

    QByteArray identity = path.toUtf8();
    identity.append('\0');
    identity.append(QByteArray::number(fileInfo.size()));
    identity.append('\0');
    identity.append(QByteArray::number(fileInfo.lastModified().toMSecsSinceEpoch()));

    return QString::fromLatin1(
        QCryptographicHash::hash(identity, QCryptographicHash::Sha256).toHex());
}

QVariantMap FileSystemNavigator::saveCollection(const QUrl &url, const QVariantMap &collection) const
{
    QVariantMap result;
    const auto setError = [&result](const QString &message) {
        result.insert(QStringLiteral("success"), false);
        result.insert(QStringLiteral("error"), message);
    };

    if (!url.isLocalFile()) {
        setError(tr("The collection must be saved to a local file."));
        return result;
    }

    const QVariantList photos = collection.value(QStringLiteral("photos")).toList();
    if (photos.isEmpty()) {
        setError(tr("The collection is empty."));
        return result;
    }

    QString path = url.toLocalFile();
    if (!path.endsWith(QStringLiteral(".q2c"), Qt::CaseInsensitive))
        path.append(QStringLiteral(".q2c"));

    QJsonObject documentObject;
    documentObject.insert(QStringLiteral("format"), QStringLiteral("Q2PhotoPoint Collection"));
    documentObject.insert(QStringLiteral("version"), 1);
    documentObject.insert(QStringLiteral("createdAt"), QDateTime::currentDateTimeUtc().toString(Qt::ISODateWithMs));
    documentObject.insert(QStringLiteral("selectedIndex"), collection.value(QStringLiteral("selectedIndex")).toInt());
    documentObject.insert(QStringLiteral("photos"), QJsonArray::fromVariantList(photos));

    QSaveFile file(path);
    if (!file.open(QIODevice::WriteOnly)) {
        setError(tr("Could not open the collection file: %1").arg(file.errorString()));
        return result;
    }

    const QByteArray json = QJsonDocument(documentObject).toJson(QJsonDocument::Indented);
    if (file.write(json) != json.size()) {
        setError(tr("Could not write the collection file: %1").arg(file.errorString()));
        file.cancelWriting();
        return result;
    }

    if (!file.commit()) {
        setError(tr("Could not finish saving the collection: %1").arg(file.errorString()));
        return result;
    }

    result.insert(QStringLiteral("success"), true);
    result.insert(QStringLiteral("path"), path);
    return result;
}

QVariantMap FileSystemNavigator::loadCollection(const QUrl &url) const
{
    QVariantMap result;
    const auto setError = [&result](const QString &message) {
        result.insert(QStringLiteral("success"), false);
        result.insert(QStringLiteral("error"), message);
    };

    if (!url.isLocalFile()) {
        setError(tr("The collection must be opened from a local file."));
        return result;
    }

    QFile file(url.toLocalFile());
    if (!file.open(QIODevice::ReadOnly)) {
        setError(tr("Could not open the collection file: %1").arg(file.errorString()));
        return result;
    }

    QJsonParseError parseError;
    const QJsonDocument document = QJsonDocument::fromJson(file.readAll(), &parseError);
    if (parseError.error != QJsonParseError::NoError || !document.isObject()) {
        setError(tr("The selected file is not a valid JSON collection: %1").arg(parseError.errorString()));
        return result;
    }

    const QJsonObject object = document.object();
    if (object.value(QStringLiteral("format")).toString() != QStringLiteral("Q2PhotoPoint Collection") ||
        object.value(QStringLiteral("version")).toInt(-1) != 1 ||
        !object.value(QStringLiteral("photos")).isArray()) {
        setError(tr("The selected file is not a supported Q2PhotoPoint collection."));
        return result;
    }

    const QJsonArray photos = object.value(QStringLiteral("photos")).toArray();
    const QJsonValue selectedIndexValue = object.value(QStringLiteral("selectedIndex"));
    const int selectedIndex = selectedIndexValue.toInt(-1);
    if (!selectedIndexValue.isDouble() ||
        (photos.isEmpty() ? selectedIndex != -1 : selectedIndex < 0 || selectedIndex >= photos.size())) {
        setError(tr("The collection has an invalid selected photo index."));
        return result;
    }

    for (const QJsonValue &photoValue : photos) {
        if (!photoValue.isObject()) {
            setError(tr("The collection contains an invalid photo entry."));
            return result;
        }

        const QJsonObject photo = photoValue.toObject();
        const QJsonValue rotation = photo.value(QStringLiteral("rotation"));
        const QJsonValue zoomFactor = photo.value(QStringLiteral("zoomFactor"));
        const QJsonValue scrollX = photo.value(QStringLiteral("scrollX"));
        const QJsonValue scrollY = photo.value(QStringLiteral("scrollY"));
        if (!photo.value(QStringLiteral("path")).isString() ||
            photo.value(QStringLiteral("path")).toString().isEmpty() ||
            !photo.value(QStringLiteral("fileName")).isString() ||
            !photo.value(QStringLiteral("hash")).isString() ||
            photo.value(QStringLiteral("hash")).toString().isEmpty() ||
            !rotation.isDouble() || rotation.toInt(-1) < 0 ||
            rotation.toInt(-1) > 270 || rotation.toInt(-1) % 90 != 0 ||
            !zoomFactor.isDouble() || zoomFactor.toDouble() < 1.0 || zoomFactor.toDouble() > 8.0 ||
            !scrollX.isDouble() || scrollX.toDouble() < 0.0 ||
            !scrollY.isDouble() || scrollY.toDouble() < 0.0) {
            setError(tr("The collection contains an incomplete photo entry."));
            return result;
        }
    }

    result.insert(QStringLiteral("success"), true);
    result.insert(QStringLiteral("collection"), object.toVariantMap());
    return result;
}
