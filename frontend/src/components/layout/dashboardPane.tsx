type DashboardPaneProps = {
    title: string
    children: React.ReactNode
}

function DashboardPane({ title, children }: DashboardPaneProps) {
    return (
        <section className="dashboardPane">
            <div className="dashboardHeader">
            <h2>{title}</h2>
            </div>
            <div className="dashboard-pane-content">
                {children}
            </div>
        </section>
    )
}

export default DashboardPane