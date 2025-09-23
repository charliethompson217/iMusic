//
//  SliderView.swift
//  iMusic
//
//  Created by charles thompson on 9/22/25.
//

import SwiftUI

struct SettingsSliderView: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        HStack {
            Text(label)
                .frame(width: 100, alignment: .leading)
            CustomSlider(value: $value, range: range, step: step)
                .padding(.vertical, 6)
        }
    }
}

struct CustomSlider: NSViewRepresentable {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    func makeNSView(context: Context) -> NSSlider {
        let slider = NSSlider(value: value, minValue: range.lowerBound, maxValue: range.upperBound, target: context.coordinator, action: #selector(Coordinator.valueChanged(_:)))
        slider.isContinuous = true
        slider.controlSize = .regular
        slider.tickMarkPosition = .below
        slider.numberOfTickMarks = 0
        return slider
    }

    func updateNSView(_ nsView: NSSlider, context: Context) {
        nsView.doubleValue = value
        nsView.minValue = range.lowerBound
        nsView.maxValue = range.upperBound
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(value: $value)
    }

    class Coordinator: NSObject {
        @Binding var value: Double

        init(value: Binding<Double>) {
            self._value = value
            super.init()
        }

        @objc func valueChanged(_ sender: NSSlider) {
            value = sender.doubleValue
        }
    }
}
