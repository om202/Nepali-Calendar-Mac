//
//  WidgetsView.swift
//  Nepali-Calendar-App
//
//  Onboarding page that tells users the app ships with desktop widgets,
//  shows previews of each, and links to the macOS widget gallery.
//

import SwiftUI

struct WidgetsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {

                header

                previewGallery

                howToAddSection

                Spacer(minLength: 6)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.3.group.fill")
                    .font(.title2)
                    .foregroundStyle(nepaliCrimson)
                Text("Widgets")
                    .font(.title2.weight(.bold))
            }
            Text("Pin today's Nepali (BS) date to your desktop or Notification Center. Updates automatically at midnight Nepal time.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Previews

    private var previewGallery: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Available")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            HStack(spacing: 10) {
                smallBSPreview
                smallBSDarkPreview
                iLoveNepalPreview
            }

            mediumBSPreview
            mediumBSDarkPreview

            Text("I Love Cities")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.top, 4)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                iLoveCityPreview("Kathmandu")
                iLoveCityPreview("Pokhara")
                iLoveCityPreview("Lalitpur")
                iLoveCityPreview("Biratnagar")
                iLoveCityPreview("Birgunj")
                iLoveCityPreview("Bharatpur")
                iLoveCityPreview("Butwal")
                iLoveCityPreview("Dharan")
                iLoveCityPreview("Janakpur")
                iLoveCityPreview("Hetauda")
                iLoveCityPreview("Nepalgunj")
                iLoveCityPreview("Kalaiya")
                iLoveCityPreview("Rajbiraj")
                iLoveCityPreview("Bhaktapur")
                iLoveCityPreview("Gorkha")
                iLoveCityPreview("Tansen")
                iLoveCityPreview("Ilam")
                iLoveCityPreview("Namche")
                iLoveCityPreview("Bandipur")
                iLoveCityPreview("Jomsom")
                iLoveCityPreview("Gaur")
            }
        }
    }

    private var smallBSPreview: some View {
        WidgetPreviewCard(title: "Nepali Calendar", subtitle: "Small") {
            VStack(spacing: 2) {
                Text(sampleBSMonthYear)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                Text(sampleBSDay)
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(sampleBSDayOfWeek)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(crimsonGradient)
        }
    }

    private var smallBSDarkPreview: some View {
        WidgetPreviewCard(title: "Nepali Calendar", subtitle: "Small Dark") {
            VStack(spacing: 2) {
                Text(sampleBSMonthYear)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                Text(sampleBSDay)
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(sampleBSDayOfWeek)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(darkGradient)
        }
    }

    private var iLoveNepalPreview: some View {
        WidgetPreviewCard(title: "I Love Nepal", subtitle: "Small") {
            VStack(spacing: 3) {
                Spacer(minLength: 0)
                HStack(spacing: 4) {
                    Text("I Love")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Image(systemName: "heart.fill")
                        .foregroundStyle(nepaliCrimson)
                        .font(.system(size: 12))
                }
                HStack(spacing: 4) {
                    Text("Nepal")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Image("NepaliFlag")
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 12)
                }
                Spacer(minLength: 4)
                Text("\(sampleBSDay) \(sampleBSMonthYear)")
                    .font(.system(size: 8, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.bottom, 4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(darkGradient)
        }
    }

    private func iLoveCityPreview(_ city: String) -> some View {
        let nameSize: CGFloat = {
            switch city.count {
            case ...6:  return 14
            case 7:     return 13
            case 8:     return 12
            case 9:     return 11
            default:    return 10
            }
        }()
        return WidgetPreviewCard(title: "I Love \(city)", subtitle: "Small") {
            VStack(spacing: 3) {
                Spacer(minLength: 0)
                HStack(spacing: 4) {
                    Text("I Love")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Image(systemName: "heart.fill")
                        .foregroundStyle(nepaliCrimson)
                        .font(.system(size: 12))
                }
                HStack(spacing: 4) {
                    Text(city)
                        .font(.system(size: nameSize, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Image("NepaliFlag")
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFit()
                        .frame(height: nameSize - 2)
                }
                Spacer(minLength: 4)
                Text("\(sampleBSDay) \(sampleBSMonthYear)")
                    .font(.system(size: 8, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.bottom, 4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(darkGradient)
        }
    }

    private var mediumBSPreview: some View {
        WidgetPreviewCard(title: "Nepali Calendar", subtitle: "Medium", aspect: 2.1) {
            HStack(spacing: 0) {
                VStack(spacing: 2) {
                    Text(sampleBSMonthYear)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                    Text(sampleBSDay)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(sampleBSDayOfWeek)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Rectangle()
                    .fill(.white.opacity(0.28))
                    .frame(width: 1)
                    .padding(.vertical, 10)

                VStack(spacing: 2) {
                    Text(sampleADMonthYear)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                    Text(sampleADDay)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(sampleADDayOfWeek)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(crimsonGradient)
        }
    }

    private var mediumBSDarkPreview: some View {
        WidgetPreviewCard(title: "Nepali Calendar", subtitle: "Medium Dark", aspect: 2.1) {
            HStack(spacing: 0) {
                VStack(spacing: 2) {
                    Text(sampleBSMonthYear)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                    Text(sampleBSDay)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(sampleBSDayOfWeek)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Rectangle()
                    .fill(.white.opacity(0.28))
                    .frame(width: 1)
                    .padding(.vertical, 10)

                VStack(spacing: 2) {
                    Text(sampleADMonthYear)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                    Text(sampleADDay)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(sampleADDayOfWeek)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(darkGradient)
        }
    }

    // MARK: - How to add

    private var howToAddSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How to add")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            stepRow(number: 1,
                    title: "Right-click anywhere on your desktop",
                    subtitle: "Or click the date/time in the top-right menu bar.")
            stepRow(number: 2,
                    title: "Choose \"Edit Widgets…\"",
                    subtitle: "macOS opens the widget gallery.")
            stepRow(number: 3,
                    title: "Search \"Nepali Calendar\"",
                    subtitle: "Drag a widget to your desktop or Notification Center.")
        }
    }

    private func stepRow(number: Int, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(nepaliCrimson, in: Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Sample strings (for previews)

    private var sampleBSDay: String {
        toNepaliNumeral(BikramSambat.currentNepaliDate().day)
    }

    private var sampleBSMonthYear: String {
        let bs = BikramSambat.currentNepaliDate()
        let name = bsMonthNamesNepali[bs.month - 1]
        return "\(name) \(toNepaliNumeral(bs.year))"
    }

    private var sampleBSDayOfWeek: String {
        BikramSambat.dayOfWeekNepali(BikramSambat.currentNepaliDate())
    }

    private var sampleADDay: String {
        var cal = Calendar(identifier: .gregorian); cal.timeZone = nepalTimeZone
        return "\(cal.component(.day, from: Date()))"
    }

    private var sampleADMonthYear: String {
        let f = DateFormatter()
        f.timeZone = nepalTimeZone
        f.dateFormat = "MMMM yyyy"
        return f.string(from: Date())
    }

    private var sampleADDayOfWeek: String {
        BikramSambat.dayOfWeekEnglish(BikramSambat.currentNepaliDate())
    }
}

// MARK: - Preview card wrapper

private struct WidgetPreviewCard<Content: View>: View {
    let title: String
    let subtitle: String
    var aspect: CGFloat = 1.0
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            content()
                .aspectRatio(aspect, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.12), radius: 4, y: 2)

            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, 2)
        }
    }
}

// MARK: - Gradients (match the real widget)

private let crimsonGradient = LinearGradient(
    colors: [
        Color(red: 0.86, green: 0.08, blue: 0.24),
        Color(red: 0.50, green: 0.00, blue: 0.10)
    ],
    startPoint: .top,
    endPoint: .bottom
)

private let darkGradient = LinearGradient(
    colors: [
        Color(red: 0.12, green: 0.12, blue: 0.14),
        Color(red: 0.08, green: 0.08, blue: 0.10)
    ],
    startPoint: .top,
    endPoint: .bottom
)
