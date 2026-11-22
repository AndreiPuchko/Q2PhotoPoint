#include "FileSystemNavigator.h"

#include <QCryptographicHash>
#include <QDateTime>
#include <QDir>
#include <QFileInfo>
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
