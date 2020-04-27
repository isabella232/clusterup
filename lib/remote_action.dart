import 'package:intl/intl.dart';

typedef Filter = RemoteActionStatus Function(List<String> lines);

enum RemoteActionStatus { Unknown, Success, Warning, Error }

class RemoteAction {
  String name;
  String description;
  List<String> commands = [];
  Filter filter;
  RemoteActionStatus status = RemoteActionStatus.Unknown;
  String filtered;
  RemoteAction(this.name);

  static Set<RemoteAction> allActions() {
    return Set.from([
      RemoteAction.getDiskFreeAction(),
      RemoteAction.getUptimeAction(),
      RemoteAction.getUpdatesAvailableAction(),
    ]);
  }

  static Set<RemoteAction> getActionsFor(List<String> names) {
    Set<RemoteAction> actions = Set<RemoteAction>();
    names.forEach((String name) {
      actions.add(RemoteAction.getActionFor(name));
    });
    return actions;
  }

  @override
  bool operator ==(dynamic other) {
    return this.name == other.name;
  }

  @override
  int get hashCode => name.hashCode;

  String toJson() {
    return name;
  }

  factory RemoteAction.getActionFor(String name) {
    switch (name) {
      case "df":
        return RemoteAction.getDiskFreeAction();
        break;
      case "uptime":
        return RemoteAction.getUptimeAction();
        break;
      case "updates":
        return RemoteAction.getUpdatesAvailableAction();
        break;
      default:
        return RemoteAction("");
    }
  }

  RemoteAction.getDiskFreeAction() {
    name = "df";
    description = "checks free disk space on /";
    commands.add("df /");
    filter = (lines) {
      status = RemoteActionStatus.Unknown;

      // sth went wrong
      if (lines.length < 2) {
        return status;
      }

      RegExp regExp = new RegExp("(\\d+)%");
      RegExpMatch match = regExp.firstMatch(lines[1]);

      if (match == null) {
        return status;
      }

      if (match.groupCount != 1) {
        return status;
      }

      int percent = int.tryParse(match[1]);

      if (percent == null) {
        return status;
      }

      filtered = "$percent% used space";

      if (percent < 50)
        status = RemoteActionStatus.Success;
      else if (percent < 80)
        status = RemoteActionStatus.Warning;
      else if (percent >= 80) status = RemoteActionStatus.Error;

      return status;
    };
  }
  RemoteAction.getUptimeAction() {
    name = "uptime";
    description = "checks uptime";
    commands.add("uptime -s");
    filter = (lines) {
      // sth went wrong
      if (lines.length < 1) return RemoteActionStatus.Unknown;

      DateFormat format = DateFormat("yyyy-MM-dd hh:mm:ss");
      DateTime started = format.parse(lines[0]);
      int days = DateTime.now().difference(started).inDays;
      filtered = "$days days";

      status = RemoteActionStatus.Success;
      return status;
    };
  }
  RemoteAction.getUpdatesAvailableAction() {
    name = "updates";
    description = "checks available updates";
    commands.add("apt list --upgradeable");
    filter = (stdout) {
      int lc = stdout.split("\n").length - 1; // minus "Listing... Done" message
      filtered = lc.toString();
      if (lc > 0)
        status = RemoteActionStatus.Warning;
      else
        status = RemoteActionStatus.Success;
      return status;
    };
  }
}
