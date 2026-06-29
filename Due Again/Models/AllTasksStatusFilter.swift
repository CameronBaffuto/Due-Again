enum AllTasksStatusFilter: String, CaseIterable, Identifiable {
    case all
    case due
    case upcoming
    case archived

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All Statuses"
        case .due: "Due"
        case .upcoming: "Upcoming"
        case .archived: "Archived"
        }
    }

    var symbolName: String {
        switch self {
        case .all: "line.3.horizontal.decrease.circle"
        case .due: "exclamationmark.circle"
        case .upcoming: "calendar"
        case .archived: "archivebox"
        }
    }
}
