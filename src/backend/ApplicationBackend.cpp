#include "ApplicationBackend.h"

ApplicationBackend::ApplicationBackend(QObject *parent)
    : QObject(parent)
{
}

int ApplicationBackend::currentPage() const
{
    return m_currentPage;
}

void ApplicationBackend::navigateTo(int page)
{
    if (page < 0 || page > 3)
        return;

    if (m_currentPage == page)
        return;

    m_currentPage = page;

    emit currentPageChanged();
}
