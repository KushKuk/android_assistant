import 'package:voice_assistant/capabilities/assistant_capability.dart';
import 'package:voice_assistant/commands/assistant_command.dart';
import 'package:voice_assistant/models/execution_result.dart';
import 'package:voice_assistant/services/assistant_platform.dart';

/// Capability for handling SpotifyCommand execution.
///
/// This capability encapsulates Spotify control logic and delegates
/// to the AssistantPlatform for actual implementation.
class SpotifyCapability implements AssistantCapability {
  final AssistantPlatform _platform;

  SpotifyCapability(this._platform);

  @override
  bool canHandle(AssistantCommand command) {
    return command is SpotifyOpenCommand ||
        command is SpotifyPlaybackCommand ||
        command is SpotifyPlayTrackCommand ||
        command is SpotifyPlayArtistCommand ||
        command is SpotifyPlayPlaylistCommand;
  }

  @override
  Future<ExecutionResult> execute(AssistantCommand command) async {
    if (!canHandle(command)) {
      return ExecutionResult.invalidArguments(
          'SpotifyCapability can only handle SpotifyCommand');
    }

    // Check if Spotify is installed before executing any command
    final isInstalled = await _platform.isSpotifyInstalled();
    if (!isInstalled) {
      return ExecutionResult.unavailable('Spotify is not installed');
    }

    try {
      if (command is SpotifyOpenCommand) {
        await _platform.openSpotify();
        return ExecutionResult(status: ExecutionStatus.success, message: 'Opening Spotify');
      } else if (command is SpotifyPlaybackCommand) {
        final playbackCommand = command as SpotifyPlaybackCommand;
        if (playbackCommand.isPlay) {
          await _platform.playSpotify();
          return ExecutionResult(status: ExecutionStatus.success, message: 'Playing Spotify');
        } else if (playbackCommand.isPause) {
          await _platform.pauseSpotify();
          return ExecutionResult(status: ExecutionStatus.success, message: 'Pausing Spotify');
        } else if (playbackCommand.isResume) {
          await _platform.resumeSpotify();
          return ExecutionResult(status: ExecutionStatus.success, message: 'Resuming Spotify');
        } else if (playbackCommand.isNext) {
          await _platform.nextSpotify();
          return ExecutionResult(status: ExecutionStatus.success, message: 'Skipping to next track');
        } else if (playbackCommand.isPrevious) {
          await _platform.previousSpotify();
          return ExecutionResult(status: ExecutionStatus.success, message: 'Skipping to previous track');
        }
      } else if (command is SpotifyPlayTrackCommand) {
        final trackCommand = command as SpotifyPlayTrackCommand;
        await _platform.searchAndPlayTrack(trackCommand.query);
        return ExecutionResult(status: ExecutionStatus.success, message: 'Playing track: ${trackCommand.query}');
      } else if (command is SpotifyPlayArtistCommand) {
        final artistCommand = command as SpotifyPlayArtistCommand;
        await _platform.searchAndPlayArtist(artistCommand.query);
        return ExecutionResult(status: ExecutionStatus.success, message: 'Playing artist: ${artistCommand.query}');
      } else if (command is SpotifyPlayPlaylistCommand) {
        final playlistCommand = command as SpotifyPlayPlaylistCommand;
        await _platform.searchAndPlayPlaylist(playlistCommand.query);
        return ExecutionResult(status: ExecutionStatus.success, message: 'Playing playlist: ${playlistCommand.query}');
      }
    } on Exception catch (e) {
      return ExecutionResult.failure('Spotify execution failed: $e');
    }

    // Should not reach here if canHandle is true and all cases are covered.
    return ExecutionResult.unsupported('Unsupported Spotify command');
  }
}