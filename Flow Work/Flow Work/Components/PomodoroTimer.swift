//
//  PomodoroTimer.swift
//  Flow Work
//
//  Created by Allen Lin on 10/23/23.
//

import SwiftUI

struct PomodoroTimer: View {
    @ObservedObject var viewModel: SessionViewModel
    
    var body: some View {
        HStack(alignment: .center) {
            Text(viewModel.timeString(from: viewModel.timeRemaining))
                .font(.title)
                .fontWeight(.bold)
            Spacer()
            HStack(spacing: 10) {
                Group {
                    if viewModel.isTimerRunning {
                        Button(action: {
                            viewModel.pauseTimer()
                            viewModel.playClickSound()
                        }) {
                            Image(systemName: "pause.fill")
                                .resizable()
                                .frame(width: 15, height: 15)
                                .foregroundColor(Color("Primary"))
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        Button(action: {
                            viewModel.startTimer()
                            viewModel.playClickSound()
                        }) {
                            Image(systemName: "play.fill")
                                .resizable()
                                .frame(width: 15, height: 15)
                                .foregroundColor(Color("Primary"))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                Button(action: {
                    viewModel.resetTimer()
                    viewModel.playTickSound()
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .resizable()
                        .frame(width: 15, height: 15)
                        .foregroundColor(Color("Primary"))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(0)
        .frame(height: 30)
    }
}
