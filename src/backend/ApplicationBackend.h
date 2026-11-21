#pragma once

#include <QObject>
#include <QtQml/qqmlregistration.h>


class ApplicationBackend : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(
        int currentPage
            READ currentPage
                NOTIFY currentPageChanged
        )

public:
    explicit ApplicationBackend(QObject *parent = nullptr);

    int currentPage() const;

    Q_INVOKABLE void navigateTo(int page);

signals:
    void currentPageChanged();

private:
    int m_currentPage = 0;
};
