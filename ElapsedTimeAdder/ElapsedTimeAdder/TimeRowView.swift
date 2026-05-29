//
//  TimeRowView.swift
//  ElapsedTimeAdder
//
//  UI for a single time-entry row.

import SwiftUI

struct TimeRowView: View {
    @Bindable var row: TimeRow
    var isLast: Bool = false
    var onAddRow: (() -> Void)? = nil
    var isEditMode: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    private var hoursValid:   Bool { isValidTimeInput(row.hours) }
    private var minutesValid: Bool { isValidTimeInput(row.minutes) }
    private var secondsValid: Bool { isValidTimeInput(row.seconds) }
    private var hasError:     Bool { !hoursValid || !minutesValid || !secondsValid }

    private var rowBackgroundOpacity: Double { colorScheme == .dark ? 0.12 : 0.08 }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if isEditMode {
                // Edit mode: two-line layout so system delete/reorder controls have room
                titleField
                timeFieldsRow
            } else {
                // Normal mode: original single-line layout
                HStack(spacing: 8) {
                    titleField
                    timeFieldsRow
                }
            }

            // Error message
            if hasError {
                HStack(spacing: 8) {
                    if !isEditMode { Color.clear.frame(maxWidth: .infinity) }
                    Text("Positive numbers, you silly goose!")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(width: 55 * 3 + 8 * 2, alignment: .leading)
                        .accessibilityLabel("Invalid input. Positive numbers, you silly goose!")
                        .accessibilityIdentifier("errorMessage")
                    Color.clear.frame(width: 64)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(row.isSubtracting ? Color.red.opacity(rowBackgroundOpacity) : Color.green.opacity(rowBackgroundOpacity))
        )
    }

    @ViewBuilder private var titleField: some View {
#if os(iOS)
        TextField("", text: $row.title,
                  prompt: Text("title").foregroundColor(.primary.opacity(0.5)))
            .textFieldStyle(.roundedBorder)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Row title")
#else
        TextField("", text: $row.title,
                  prompt: Text("title (opt)").foregroundColor(.primary.opacity(0.5)))
            .textFieldStyle(.roundedBorder)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Row title")
#endif
    }

    private var timeFieldsRow: some View {
        HStack(spacing: 8) {
            TextField("", text: $row.hours,
                      prompt: Text("0").foregroundColor(.primary.opacity(0.6)))
                .textFieldStyle(.roundedBorder)
                .frame(width: 55)
                .multilineTextAlignment(.center)
                .accessibilityLabel("Hours")
                .overlay(fieldBorder(valid: hoursValid))
#if os(iOS)
                .keyboardType(.decimalPad)
#endif

            TextField("", text: $row.minutes,
                      prompt: Text("0").foregroundColor(.primary.opacity(0.6)))
                .textFieldStyle(.roundedBorder)
                .frame(width: 55)
                .multilineTextAlignment(.center)
                .accessibilityLabel("Minutes")
                .overlay(fieldBorder(valid: minutesValid))
#if os(iOS)
                .keyboardType(.decimalPad)
#endif

            TextField("", text: $row.seconds,
                      prompt: Text("0").foregroundColor(.primary.opacity(0.6)))
                .textFieldStyle(.roundedBorder)
                .frame(width: 55)
                .multilineTextAlignment(.center)
                .accessibilityLabel("Seconds")
                .overlay(fieldBorder(valid: secondsValid))
                .modifier(TabToAddRowModifier(isLast: isLast, action: onAddRow))
#if os(iOS)
                .keyboardType(.decimalPad)
#endif

            Picker("Add or subtract this row", selection: $row.isSubtracting) {
                Text("+").tag(false).accessibilityLabel("Add")
                Text("−").tag(true).accessibilityLabel("Subtract")
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 64)
#if os(macOS)
            .tint(row.isSubtracting ? Color.red.opacity(0.55) : Color.green.opacity(0.55))
#else
            .tint(row.isSubtracting ? .red : .green)
#endif
            .accessibilityLabel("Add or subtract this row")
            .accessibilityIdentifier("toggleButton")
        }
    }

    private func fieldBorder(valid: Bool) -> some View {
        RoundedRectangle(cornerRadius: 6)
            .stroke(valid ? Color.clear : Color.red, lineWidth: 2)
    }
}

// Applies onKeyPress(.tab) only when isLast is true — no modifier at all on other rows,
// which avoids disrupting List's touch delivery.
private struct TabToAddRowModifier: ViewModifier {
    let isLast: Bool
    let action: (() -> Void)?

    func body(content: Content) -> some View {
        if isLast, let action {
            content.onKeyPress(.tab) {
                action()
                return .handled
            }
        } else {
            content
        }
    }
}
