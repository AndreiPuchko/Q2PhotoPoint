#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QUrl>
#include <QtQml/qqmlregistration.h>

class FileSystemNavigator : public QObject
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit FileSystemNavigator(QObject *parent = nullptr);

    Q_INVOKABLE QVariantList availableWindowsDrives() const;
    Q_INVOKABLE QString imageStateHash(const QUrl &url) const;
    Q_INVOKABLE QVariantMap saveCollection(const QUrl &url, const QVariantMap &collection) const;
    Q_INVOKABLE QVariantMap loadCollection(const QUrl &url) const;
};
