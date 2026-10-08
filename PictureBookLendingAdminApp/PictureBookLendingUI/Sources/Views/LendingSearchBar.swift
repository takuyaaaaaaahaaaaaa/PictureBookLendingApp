import SwiftUI

#if canImport(UIKit)
    import UIKit

    public struct LendingSearchBar: View {
        @Binding var searchText: String
        @Binding var isSearchFocused: Bool
        var prompt = "タイトル・著者で検索"
        var onCoverSearch: (() -> Void)? = nil
        @Environment(\.dynamicTypeSize) private var dynamicTypeSize

        public init(
            searchText: Binding<String>, isSearchFocused: Binding<Bool>,
            prompt: String = "タイトル・著者で検索", onCoverSearch: (() -> Void)? = nil
        ) {
            self._searchText = searchText
            self._isSearchFocused = isSearchFocused
            self.prompt = prompt
            self.onCoverSearch = onCoverSearch
        }

        public var body: some View {
            GeometryReader { geometry in
                HStack(spacing: 12) {
                    NativeBookSearchBar(
                        text: $searchText, isFocused: $isSearchFocused, prompt: prompt
                    )
                    .frame(minWidth: 140)
                    if let onCoverSearch {
                        Button(action: onCoverSearch) {
                            Label {
                                Text("表紙で検索").font(.headline)
                            } icon: {
                                Image(systemName: "camera.viewfinder").font(
                                    .system(size: 26, weight: .semibold))
                            }
                            .labelStyle(
                                AdaptiveCoverLabelStyle(
                                    showsTitle: geometry.size.width >= 600
                                        && !dynamicTypeSize.isAccessibilitySize)
                            )
                            .frame(minWidth: 44, minHeight: 44)
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityLabel("表紙で検索")
                    }
                }
            }
            .frame(height: 60)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(Color(uiColor: .systemBackground))
        }
    }

    private struct AdaptiveCoverLabelStyle: LabelStyle {
        let showsTitle: Bool
        func makeBody(configuration: Configuration) -> some View {
            HStack(spacing: 8) {
                configuration.icon
                if showsTitle { configuration.title }
            }
        }
    }

    /// Standard UIKit search field, kept alongside the cover search action.
    private struct NativeBookSearchBar: UIViewRepresentable {
        @Binding var text: String
        @Binding var isFocused: Bool
        let prompt: String

        func makeUIView(context: Context) -> UISearchBar {
            let view = UISearchBar()
            view.delegate = context.coordinator
            view.placeholder = prompt
            view.accessibilityLabel = prompt
            view.searchBarStyle = .minimal
            view.searchTextField.backgroundColor = .secondarySystemBackground
            view.searchTextField.layer.borderWidth = 1
            view.searchTextField.layer.cornerRadius = 10
            view.searchTextField.layer.borderColor =
                UIColor.separator.resolvedColor(with: view.traitCollection).cgColor
            view.searchTextField.font = .preferredFont(forTextStyle: .body)
            view.searchTextField.adjustsFontForContentSizeCategory = true
            view.setContentHuggingPriority(.defaultLow, for: .horizontal)
            view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            return view
        }
        func updateUIView(_ view: UISearchBar, context: Context) {
            context.coordinator.parent = self
            if view.text != text { view.text = text }
            view.placeholder = prompt
            view.accessibilityLabel = prompt
            view.searchTextField.layer.borderColor =
                UIColor.separator.resolvedColor(with: view.traitCollection).cgColor
            if !isFocused && view.searchTextField.isFirstResponder { view.resignFirstResponder() }
        }
        func makeCoordinator() -> Coordinator { Coordinator(self) }
        final class Coordinator: NSObject, UISearchBarDelegate {
            var parent: NativeBookSearchBar
            init(_ parent: NativeBookSearchBar) { self.parent = parent }
            func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
                parent.text = searchText
            }
            func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) { parent.isFocused = true }
            func searchBarTextDidEndEditing(_ searchBar: UISearchBar) { parent.isFocused = false }
            func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
                searchBar.resignFirstResponder()
            }
        }
    }

#endif
