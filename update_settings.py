import re

with open('lib/ui/screens/settings/settings_page.dart', 'r') as f:
    content = f.read()

# For Appearance
content = re.sub(r'onTap: \(\) => settings.setUseAmoledMode\(!settings.useAmoledMode\),', 
                 r"onTap: () { controller.closeView(null); _controller.openAppearance(context, 'AMOLED Mode'); },", content)
content = re.sub(r'onTap: \(\) => settings.setUseCdArtworkStyle\(!settings.useCdArtworkStyle\),', 
                 r"onTap: () { controller.closeView(null); _controller.openAppearance(context, 'Y2k(cd) style album art'); },", content)
content = re.sub(r'onTap: \(\) => settings.setSplitCdWhenHalfOpen\(!settings.splitCdWhenHalfOpen\),', 
                 r"onTap: () { controller.closeView(null); _controller.openAppearance(context, 'Split CD Horizontally'); },", content)
content = re.sub(r'onTap: \(\) => settings.setRotateCdWhenPlaying\(!settings.rotateCdWhenPlaying\),', 
                 r"onTap: () { controller.closeView(null); _controller.openAppearance(context, 'Revolving CD Disc'); },", content)
content = re.sub(r'onTap: \(\) => settings.setShowMiniplayerShadow\(!settings.showMiniplayerShadow\),', 
                 r"onTap: () { controller.closeView(null); _controller.openAppearance(context, 'Miniplayer Shadow'); },", content)

# For Playback
content = re.sub(r'onTap: \(\) => settings.setAutoPlay\(!settings.autoPlay\),', 
                 r"onTap: () { controller.closeView(null); _controller.openPlayback(context, 'Auto Play'); },", content)
content = re.sub(r'onTap: \(\) => settings.setSkipSilence\(!settings.skipSilence\),', 
                 r"onTap: () { controller.closeView(null); _controller.openPlayback(context, 'Skip Ending Silence'); },", content)
content = re.sub(r'onTap: \(\) => settings.setResetSpeedOnNewTrack\(!settings.resetSpeedOnNewTrack\),', 
                 r"onTap: () { controller.closeView(null); _controller.openPlayback(context, 'Reset on New Track'); },", content)
content = re.sub(r'onTap: \(\) => settings.setResumeFromPlayedDuration\(!settings.resumeFromPlayedDuration\),', 
                 r"onTap: () { controller.closeView(null); _controller.openPlayback(context, 'Remember Playback Position'); },", content)
content = re.sub(r'onTap: \(\) => settings.setUpNextIndicator\(!settings.upNextIndicator\),', 
                 r"onTap: () { controller.closeView(null); _controller.openPlayback(context, 'Up Next Indicator'); },", content)
content = re.sub(r'onTap: \(\) => settings.setSaveLyricsOffline\(!settings.saveLyricsOffline\),', 
                 r"onTap: () { controller.closeView(null); _controller.openPlayback(context, 'Save Lyrics Offline'); },", content)

# For Gestures
content = re.sub(r'onTap: \(\) => settings.setSwipeToDismiss\(!settings.swipeToDismiss\),', 
                 r"onTap: () { controller.closeView(null); _controller.openGestures(context, 'Swipe Down to Dismiss'); },", content)
content = re.sub(r'onTap: \(\) => settings.setSwipeToChangeTrack\(!settings.swipeToChangeTrack\),', 
                 r"onTap: () { controller.closeView(null); _controller.openGestures(context, 'Swipe to Change Track'); },", content)
content = re.sub(r'onTap: \(\) => settings.setFastSwipeArtwork\(!settings.fastSwipeArtwork\),', 
                 r"onTap: () { controller.closeView(null); _controller.openGestures(context, 'Fast Swipe Artwork'); },", content)
content = re.sub(r'onTap: \(\) => settings.setEnableHaptics\(!settings.enableHaptics\),', 
                 r"onTap: () { controller.closeView(null); _controller.openGestures(context, 'Haptic Feedback'); },", content)
content = re.sub(r'onTap: \(\) => settings.setSnackbarSwipeToDismiss\(!settings.snackbarSwipeToDismiss\),', 
                 r"onTap: () { controller.closeView(null); _controller.openGestures(context, 'Swipe to Dismiss SnackBar'); },", content)
content = re.sub(r'onTap: \(\) => settings.setAutoScrollQueue\(!settings.autoScrollQueue\),', 
                 r"onTap: () { controller.closeView(null); _controller.openGestures(context, 'Auto Scroll Queue'); },", content)

# Fix the ones that are already openX(context)
content = re.sub(r'onTap: \(\) \{\n\s*controller.closeView\(null\);\n\s*_controller.openAppearance\(context\);\n\s*\},', 
                 r"onTap: () { controller.closeView(null); _controller.openAppearance(context, e.title); },", content)
content = re.sub(r'onTap: \(\) \{\n\s*controller.closeView\(null\);\n\s*_controller.openGestures\(context\);\n\s*\},', 
                 r"onTap: () { controller.closeView(null); _controller.openGestures(context, e.title); },", content)
content = re.sub(r'onTap: \(\) \{\n\s*controller.closeView\(null\);\n\s*_controller.openLibrary\(context\);\n\s*\},', 
                 r"onTap: () { controller.closeView(null); _controller.openLibrary(context, e.title); },", content)


with open('lib/ui/screens/settings/settings_page.dart', 'w') as f:
    f.write(content)

