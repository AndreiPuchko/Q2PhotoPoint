#include "FileSystemNavigator.h"

#include <QCryptographicHash>
#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QImage>
#include <QImageReader>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonParseError>
#include <QPageLayout>
#include <QPageSize>
#include <QPainter>
#include <QPdfWriter>
#include <QSaveFile>
#include <QSet>
#include <QStorageInfo>
#include <QTransform>
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

QVariantMap FileSystemNavigator::exportCollectionPdf(const QUrl &url, const QVariantMap &collection) const
{
    QVariantMap result;
    const auto setError = [&result](const QString &message) {
        result.insert(QStringLiteral("success"), false);
        result.insert(QStringLiteral("error"), message);
    };

    if (!url.isLocalFile()) {
        setError(tr("The PDF must be saved to a local file."));
        return result;
    }

    const QVariantList photos = collection.value(QStringLiteral("photos")).toList();
    if (photos.isEmpty()) {
        setError(tr("The collection is empty."));
        return result;
    }

    QString path = url.toLocalFile();
    if (!path.endsWith(QStringLiteral(".pdf"), Qt::CaseInsensitive))
        path.append(QStringLiteral(".pdf"));

    QSaveFile file(path);
    if (!file.open(QIODevice::WriteOnly)) {
        setError(tr("Could not open the PDF file: %1").arg(file.errorString()));
        return result;
    }

    QPdfWriter writer(&file);
    writer.setResolution(300);
    writer.setTitle(QStringLiteral("Q2PhotoPoint collection"));
    writer.setCreator(QStringLiteral("Q2PhotoPoint"));

    QPainter painter;
    const auto fail = [&](const QString &message) {
        if (painter.isActive())
            painter.end();
        file.cancelWriting();
        setError(message);
        return result;
    };

    for (qsizetype i = 0; i < photos.size(); ++i) {
        const QVariantMap photo = photos.at(i).toMap();
        const QUrl imageUrl(photo.value(QStringLiteral("path")).toString());
        const QString fileName = photo.value(QStringLiteral("fileName")).toString();
        if (!imageUrl.isLocalFile())
            return fail(tr("Photo '%1' does not have a local file path.").arg(fileName));

        QImageReader reader(imageUrl.toLocalFile());
        reader.setAutoTransform(true);
        QImage image = reader.read();
        if (image.isNull())
            return fail(tr("Could not read photo '%1': %2").arg(fileName, reader.errorString()));

        const int rotation = photo.value(QStringLiteral("rotation")).toInt();
        if (rotation % 360 != 0)
            image = image.transformed(QTransform().rotate(rotation), Qt::SmoothTransformation);

        const qreal widthInPoints = image.width() * 72.0 / 300.0;
        const qreal heightInPoints = image.height() * 72.0 / 300.0;
        const QSizeF portraitSize(qMin(widthInPoints, heightInPoints), qMax(widthInPoints, heightInPoints));
        const QPageSize pageSize(portraitSize, QPageSize::Point, QStringLiteral("Photo"), QPageSize::ExactMatch);
        if (!pageSize.isValid())
            return fail(tr("Could not create a PDF page for photo '%1'.").arg(fileName));

        const QPageLayout::Orientation orientation = widthInPoints >= heightInPoints
            ? QPageLayout::Landscape
            : QPageLayout::Portrait;
        const QPageLayout pageLayout(pageSize, orientation, QMarginsF(0, 0, 0, 0), QPageLayout::Point);
        if (!writer.setPageLayout(pageLayout))
            return fail(tr("Could not set the PDF page size for photo '%1'.").arg(fileName));

        if (i == 0) {
            if (!painter.begin(&writer))
                return fail(tr("Could not start writing the PDF."));
        } else if (!writer.newPage()) {
            return fail(tr("Could not create a PDF page for photo '%1'.").arg(fileName));
        }

        painter.drawImage(QRect(0, 0, writer.width(), writer.height()), image);
    }

    if (!painter.end()) {
        file.cancelWriting();
        setError(tr("Could not finish writing the PDF."));
        return result;
    }
    if (!file.commit()) {
        setError(tr("Could not finish saving the PDF: %1").arg(file.errorString()));
        return result;
    }

    result.insert(QStringLiteral("success"), true);
    result.insert(QStringLiteral("path"), path);
    return result;
}

QVariantMap FileSystemNavigator::copyCollectionFiles(const QUrl &destination, const QVariantList &photos) const
{
    QVariantMap result;
    const auto setError = [&result](const QString &message) {
        result.insert(QStringLiteral("success"), false);
        result.insert(QStringLiteral("error"), message);
    };

    if (!destination.isLocalFile()) {
        setError(tr("The destination must be a local folder."));
        return result;
    }

    const QString destinationPath = destination.toLocalFile();
    const QDir destinationDir(destinationPath);
    if (!destinationDir.exists()) {
        setError(tr("The selected destination folder does not exist."));
        return result;
    }
    if (photos.isEmpty()) {
        setError(tr("The collection is empty."));
        return result;
    }

    int copiedCount = 0;
    QStringList copiedFiles;
    QSet<QString> reservedNames;

    for (const QVariant &photoValue : photos) {
        const QVariantMap photo = photoValue.toMap();
        const QUrl sourceUrl(photo.value(QStringLiteral("path")).toString());
        const QFileInfo sourceInfo(sourceUrl.toLocalFile());
        if (!sourceUrl.isLocalFile() || !sourceInfo.exists() || !sourceInfo.isFile()) {
            setError(tr("Could not find source photo: %1").arg(photo.value(QStringLiteral("fileName")).toString()));
            result.insert(QStringLiteral("copiedCount"), copiedCount);
            result.insert(QStringLiteral("copiedFiles"), copiedFiles);
            return result;
        }

        const QString fileName = sourceInfo.fileName();
        const QFileInfo nameInfo(fileName);
        const QString baseName = nameInfo.completeBaseName();
        const QString suffix = nameInfo.completeSuffix();
        QString targetName = fileName;
        int duplicateIndex = 1;
        while (true) {
            if (duplicateIndex > 1) {
                targetName = suffix.isEmpty()
                    ? QStringLiteral("%1 (%2)").arg(baseName).arg(duplicateIndex)
                    : QStringLiteral("%1 (%2).%3").arg(baseName).arg(duplicateIndex).arg(suffix);
            }

            const QString targetPath = destinationDir.filePath(targetName);
            if (reservedNames.contains(targetName.toCaseFolded()) || QFileInfo::exists(targetPath)) {
                ++duplicateIndex;
                continue;
            }

            if (QFile::copy(sourceInfo.absoluteFilePath(), targetPath))
                break;
            if (QFileInfo::exists(targetPath)) {
                ++duplicateIndex;
                continue;
            }

            setError(tr("Could not copy '%1' to the selected folder.").arg(fileName));
            result.insert(QStringLiteral("copiedCount"), copiedCount);
            result.insert(QStringLiteral("copiedFiles"), copiedFiles);
            return result;
        }

        reservedNames.insert(targetName.toCaseFolded());
        copiedFiles.append(targetName);
        ++copiedCount;
    }

    result.insert(QStringLiteral("success"), true);
    result.insert(QStringLiteral("destination"), destinationPath);
    result.insert(QStringLiteral("copiedCount"), copiedCount);
    result.insert(QStringLiteral("copiedFiles"), copiedFiles);
    return result;
}
