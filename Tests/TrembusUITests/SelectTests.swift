import AppKit
import SwiftUI
import Testing

@testable import TrembusTokens
@testable import TrembusUI

// Rendering in every theme and the contract are already covered for Select by RenderTests
// and ContractTests. This file is for its OWN LOGIC: which option counts as chosen, what the
// closed field says, what may become the selection, and what the native menu is built from.

@Suite("Select")
struct SelectTests {
    static let options = [
        SelectOption("Owner", value: "owner", isEnabled: false),
        SelectOption("Admin", value: "admin"),
        SelectOption("Editor", value: "editor"),
    ]

    /// A selection that outlives the view, as `@State` would. Unchecked-Sendable because a `Binding`'s
    /// closures must be Sendable; every test here runs on the main actor.
    nonisolated final class Chosen<Value>: @unchecked Sendable {
        var value: Value
        init(_ value: Value) { self.value = value }

        var binding: Binding<Value> { Binding(get: { self.value }, set: { self.value = $0 }) }
    }

    static func select(_ chosen: Chosen<String?>, prompt: String = "Choose a role") -> Select<String> {
        Select("Role", selection: chosen.binding, options: options, prompt: prompt)
    }

    @Test func theClosedFieldSaysTheChosenOptionElseThePrompt() {
        #expect(Self.select(Chosen("editor")).shownText == "Editor")
        #expect(Self.select(Chosen(nil)).shownText == "Choose a role")
        #expect(Self.select(Chosen(nil), prompt: "").shownText.isEmpty)
    }

    @Test func aValueTheListLacksReadsAsNothingChosen() {
        // The field must never show words it did not offer.
        let select = Self.select(Chosen("gone"))
        #expect(select.chosenIndex == nil)
        #expect(select.shownText == "Choose a role")
    }

    @Test func onlyARowThatExistsAndIsEnabledBecomesTheSelection() {
        let chosen = Chosen<String?>("admin")
        let select = Self.select(chosen)
        select.choose(2)
        #expect(chosen.value == "editor")
        select.choose(0)  // Owner: in the list, but dimmed
        #expect(chosen.value == "editor")
        select.choose(99)  // a stale row from a list that has since shrunk — no trap
        select.choose(-1)
        #expect(chosen.value == "editor")
    }

    @Test func aSelectionThatIsNeverEmptyIgnoresNil() {
        let sort = Chosen("newest")
        let sorts = [SelectOption("Newest first", value: "newest"), SelectOption("Name", value: "name")]
        let select = Select("Sort by", selection: sort.binding, options: sorts)
        #expect(select.shownText == "Newest first")
        select.choose(1)
        #expect(sort.value == "name")
    }

    @Test func theMenuHasOneRowPerOptionAndChecksTheChosenOne() throws {
        let view = SelectMenuView(frame: NSRect(x: 0, y: 0, width: 180, height: 30))
        view.items = Self.options.map { .init(title: $0.title, isEnabled: $0.isEnabled) }
        view.chosenIndex = 1
        var reported: [Int] = []
        view.onChoose = { reported.append($0) }

        let menu = view.makeMenu()
        #expect(menu.items.map(\.title) == ["Owner", "Admin", "Editor"])
        #expect(menu.items.map(\.state) == [.off, .on, .off])
        #expect(menu.items.map(\.isEnabled) == [false, true, true])
        #expect(menu.minimumWidth == 180, "the list is never narrower than the field")

        // What AppKit does when a row is chosen. (`performActionForItem` goes through NSApp — nil in a test.)
        let row = menu.items[2]
        _ = row.target?.perform(try #require(row.action), with: row)
        #expect(reported == [2])
    }
}
