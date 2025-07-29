import SwiftUI

/// Displays all workers with their current location fetched from the backend
struct WorkersListView: View {
    @StateObject private var viewModel = WorkersListViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if let error = viewModel.errorMessage {
                    Text("Fehler: \(error)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                } else if viewModel.allWorkers.isEmpty {
                    ProgressView("Lade Mitarbeiter…")
                } else {
                    List(viewModel.filteredWorkers) { worker in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(worker.userName)
                                Text(worker.locationName ?? "Abwesend")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Mitarbeiter")
            .searchable(text: $viewModel.searchText)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Picker("Sort", selection: $viewModel.sortOption) {
                        ForEach(SortOption.allCases) { opt in
                            Text(opt.rawValue).tag(opt)
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Refresh") { viewModel.loadWorkers() }
                }
            }
        }
    }
}

struct WorkersListView_Previews: PreviewProvider {
    static var previews: some View {
        WorkersListView()
    }
}
