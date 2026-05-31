type DashboardPaneProps = {
    title: string
    children: React.ReactNode
}

function DashboardPane({ title, children }: DashboardPaneProps) {
    return (
        <section className="dashboard-pane">
            <h2>{title}</h2>
            <div className="dashboard-pane-content">
                {children}
            </div>
        </section>
    )
}

export default DashboardPane