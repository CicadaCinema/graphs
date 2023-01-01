import '../graph_layout.dart';

/// After creating an instance of this class, you **must** call
/// [initialiseGraph] to pass graph topology data to the algorithm, then call
/// [updateLayoutParameters] to pass the dimensions of the graph drawing area.
///
/// After, call [iterate] to execute one iteration of the algorithm, or run
/// [iterateUntilStable] to repeatedly perform iterations until the layout
/// becomes stable. Access the computed layout with [nodeLayout].
abstract class InteractiveLayoutAlgorithm {
  /// The computed layout of the given graph.
  NodeLayout get nodeLayout;

  /// The nodes unaffected by iterations of the algorithm.
  Set<Node> get constrainedNodes;

  /// Initialise the algorithm with some graph topology data.
  void initialiseGraph({required Graph graphTopology});

  /// Update (or initialise) the graph layout area and the radius of each node.
  ///
  /// The layout algorithm must be aware of the node radius so that it does not
  /// produce a layout where some part of a node lies outside the node area
  /// boundaries.
  void updateLayoutParameters({
    required double width,
    required double height,
    required double nodeRadius,
  });

  /// Perform one iteration of the algorithm, updating [nodeLayout].
  ///
  /// Returns [true] if running one iteration does not change the position of
  /// each node by much in each axis.
  bool iterate();

  /// Repeatedly run [iterate] until a stable layout is obtained.
  ///
  /// This method is not guaranteed to terminate; be careful when using it on
  /// complex graphs.
  void iterateUntilStable() {
    while (!iterate()) {}
  }
}
