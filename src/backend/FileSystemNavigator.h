#pragma once

#include <QObject>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>

class FileSystemNavigator : public QObject
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit FileSystemNavigator(QObject *parent = nullptr);

    Q_INVOKABLE QVariantList availableWindowsDrives() const;
};
