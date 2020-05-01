import 'package:clusterup/remote_action.dart';
import 'package:flutter/material.dart';
import 'package:clusterup/ssh_key.dart';
import 'cluster.dart';

class ResultsViewState extends State<ResultsView> {
  SSHKey _key;
  bool _run = false;
  Cluster _cluster;
  List<RemoteAction> actions; // finished actions
  RemoteAction current;

  ResultsViewState(this._key, this._cluster, this._run);

  @override
  void initState() {
    if (_run) {
      actions = [];

      // set callback for results
      _cluster.onActionStarted = (RemoteAction action) {
        setState(() {
          current = action;
          actions.add(action);
        });
      };

      // set callback for results
      _cluster.onActionFinished = (RemoteAction action) {
        setState(() {
          current = null;
        });
      };

      // run
      _cluster.run(_key);
    } else {
      actions = this._cluster.actions.toList();
    }
  }

  @override
  void dispose() {
    _cluster.onActionStarted = (RemoteAction action) {};
    _cluster.onActionFinished = (RemoteAction action) {};
    super.dispose();
  }

  Widget _buildRow(RemoteAction action) {
    bool running = action == current;
    var ndicator = running
        ? SizedBox(
            child: CircularProgressIndicator(),
            height: 15.0,
            width: 15.0,
          )
        : Icon(Icons.done);

    if (!running) {
      switch (action.status) {
        case RemoteActionStatus.Unknown:
          ndicator = Icon(Icons.done, color: Colors.white);
          break;
        case RemoteActionStatus.Success:
          ndicator = Icon(Icons.check_circle, color: Colors.green[300]);
          break;
        case RemoteActionStatus.Warning:
          ndicator = Icon(Icons.warning, color: Colors.orange[300]);
          break;
        case RemoteActionStatus.Error:
          ndicator = Icon(Icons.error, color: Colors.red[300]);
          break;
      }
    }
    return ListTile(
      title: Text(action.name),
      subtitle: Text(action.filtered),
      trailing: ndicator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text(_run ? "Running on ${_cluster.name}" : "Last run on ${_cluster.name}"),
        ),
        body: ListView.builder(
            itemCount: actions.length,
            padding: const EdgeInsets.all(16.0),
            itemBuilder: (context, i) {
              return _buildRow(actions.elementAt(i));
            }));
  }
}

class ResultsView extends StatefulWidget {
  SSHKey _key;
  Cluster _cluster;
  bool _run = false;

  ResultsView(this._key, this._cluster, this._run);

  @override
  ResultsViewState createState() => ResultsViewState(this._key, this._cluster, this._run);
}
