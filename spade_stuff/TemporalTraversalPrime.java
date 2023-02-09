/*
--------------------------------------------------------------------------------
SPADE - Support for Provenance Auditing in Distributed Environments.
Copyright (C) 2015 SRI International

This program is free software: you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
--------------------------------------------------------------------------------
*/

package spade.transformer;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.json.JSONObject;

import spade.core.AbstractEdge;
import spade.core.AbstractTransformer;
import spade.core.AbstractVertex;
import spade.core.Graph;
import spade.reporter.audit.OPMConstants;
import spade.utility.HelperFunctions;

public class TemporalTraversalPrime extends AbstractTransformer{

        private static final Logger logger = Logger.getLogger(TemporalTraversalPrime.class.getName());
        private Boolean outputTime;
        private Double graphMinTime;
        private Double graphMaxTime;
        private String annotationName;


        private BufferedWriter outputWriter;
        
        // must specify the name of an annotation
        @Override
        public boolean initialize(String arguments){
                Map<String, String> argumentsMap = HelperFunctions.parseKeyValPairs(arguments);
                if("timestamp".equals(argumentsMap.get("order"))){
                        annotationName = "timestampNanos";
                        // annotationName = OPMConstants.EDGE_TIME;
                }else{
                        annotationName = OPMConstants.EDGE_EVENT_ID;
                }

            
                /*
                * Output Start time and end time to a file for comparisons while merging graphs 
                * used specifically for shadewatcher transitive closure merging reimplementation
                * 
                */
                outputTime = true;
            if(outputTime == true) {
                try {
                    File file =new File("/tmp/temporal_traversal.json");
                    if(!file.exists()){
                        file.createNewFile();
                    }
                    outputWriter = new BufferedWriter(new FileWriter(file, true));
                } catch (Exception e) {
                    logger.log(Level.SEVERE, "Failed to establish writer to /tmp/temporal_traversal.json", e);
                    return false;
                }
            }
            
                graphMinTime = Double.MAX_VALUE;
                graphMaxTime = Double.MIN_VALUE;
                return true;
        }

        @Override
        public LinkedHashSet<ArgumentName> getArgumentNames(){
                return new LinkedHashSet<ArgumentName>(
                                Arrays.asList(
                                                ArgumentName.SOURCE_GRAPH
                                                , ArgumentName.DIRECTION
                                                )
                                );
        }

        /*
        * Check all edges that have child matching our target Vertex and see their timestamps
        * Find edge with lowest timestamp that is our start time for our traversal
        *
        */
        public Double getMintime(AbstractVertex vertex, Set<AbstractEdge> allEdges){
                Double minTime = Double.MAX_VALUE;


                /*
                * Go over all passed edges in case of start vertex this will be all graph vertices
                * In the case of middle vertices use visited graph's edges to find minimum time
                */
                for(AbstractEdge edge : allEdges){
                        AbstractEdge newEdge = createNewWithoutAnnotations(edge);
                        if(vertex.bigHashCode().equals(newEdge.getChildVertex().bigHashCode())){
                                try{
                                        Double time = Double.parseDouble(getAnnotationSafe(newEdge, annotationName));
                                        if(time < minTime) {
                                        minTime = time;
                                        }
                                }catch(Exception e){
                                        logger.log(Level.SEVERE, "Failed to parse where " + annotationName + "='"
                                                        + getAnnotationSafe(newEdge, annotationName) + "'");
                                }
                        }
                }

                //If there are no incoming edges to vertex return mintime of -1
                if (minTime == Double.MAX_VALUE) {
                        minTime = -1.0;
                }
                return minTime;
        }

        /*
        * Get children for a vertex that are from edges with increasing time edges with lesser time will not be considered
        *
        *
        * Note: Passing adjacentGraph to collect all children from multiple vertices from one level into one graph
        */
        public Graph getAllChildrenForAVertex(AbstractVertex vertex, Graph adjacentGraph, Graph finalGraph, Graph graph, Integer levelCount){
                Double minTime = -2.0;
                Graph childGraph = null;
                if(finalGraph.vertexSet().isEmpty()) {
                        /*
                        * Calculate minimum time t1 of all incoming edges to start vertex if there
                        * are no incoming edges then returns -1
                        *
                        */

                        minTime = getMintime(vertex, graph.edgeSet());
                        childGraph = new Graph();
                } else {
                        /*
                        * Calculate minimum time t2-tn from minimum of all incoming edges in
                        * our traversed graph on the passed vertex hence ignoring edges that are
                        * from the rest of the graph which do not have causal association with
                        * the root data object vertex
                        *
                        */
                        minTime = getMintime(vertex, finalGraph.edgeSet());

                        /*
                        * Note: This code is related to outputing times to a file for Shadewatcher transitive closure and merging
                        * For Lineage(A) check all vertices between A and its children
                        * to find the lowest time in these edges we will consider this
                        * to be the graphs minimum time for merging
                        */
                        if (levelCount == 1) {
                        if (minTime < graphMinTime) {
                            graphMinTime = minTime;
                        }
                        }
                        childGraph = adjacentGraph == null ? new Graph() : adjacentGraph;
                }


                /*
                * Check all edges that are outgoing from our start vertex and compare
                * their time with lowest traversed incoming edge to the start vertex
                */
                for(AbstractEdge edge : graph.edgeSet()){
                        AbstractEdge newEdge = createNewWithoutAnnotations(edge);
                        if(vertex.bigHashCode().equals(newEdge.getParentVertex().bigHashCode())){
                                try{
                                        Double time = Double.parseDouble(getAnnotationSafe(newEdge, annotationName));
                                        if (time > minTime) {
                                        if (time > graphMaxTime) {
                                            graphMaxTime = time;
                                        }
                                        childGraph.putVertex(newEdge.getChildVertex());
                                        childGraph.putVertex(newEdge.getParentVertex());
                                        childGraph.putEdge(newEdge);
                                        }
                                }catch(Exception e){
                                        logger.log(Level.SEVERE, "Failed to parse where " + annotationName + "='"
                                                        + getAnnotationSafe(newEdge, annotationName) + "'");
                                }

                        /*
                        * Re add all parent vertices for each node visited into graph
                        *
                        */
                        } else {
                                if(vertex.bigHashCode().equals(newEdge.getChildVertex().bigHashCode())){
                                        childGraph.putVertex(newEdge.getChildVertex());
                                        childGraph.putVertex(newEdge.getParentVertex());
                                        childGraph.putEdge(newEdge);
                                }
                        }
                }
                return childGraph;
        }



        /**
            *
        */
        @Override
        public Graph transform(Graph graph, ExecutionContext context) {
                Set<AbstractVertex> currentLevel = new HashSet<AbstractVertex>();
                /*
                * Pick a start vertex to begin traversal pass it to transform method in SPADE Query client
                * Example: $1 = $2.transform(TemporalTraversalPrime, "order=timestamp", $startVertex, 'descendant')
                *
                */
                List<AbstractVertex> startGraphVertexSet = new ArrayList<AbstractVertex>(context.getSourceGraph().vertexSet());
                AbstractVertex startVertex = startGraphVertexSet.get(0);

                Integer levelCount = 0;

                currentLevel.add(startVertex);
                Graph finalGraph = new Graph();

                while(!currentLevel.isEmpty()) {
                        Graph adjacentGraph = null;
                        for(AbstractVertex node : currentLevel) {
                                // get children of current level nodes
                                // timestamp of subsequent edges > than current
                                adjacentGraph = getAllChildrenForAVertex(node, adjacentGraph, finalGraph, graph, levelCount);
                        }
                        if(! adjacentGraph.vertexSet().isEmpty()){// If children exists
                                // Add children in graph and run DFS on children
                                Set<AbstractVertex> nextLevelVertices = new HashSet<AbstractVertex>();
                                nextLevelVertices.addAll(adjacentGraph.vertexSet());
                                nextLevelVertices.removeAll(currentLevel);
                                nextLevelVertices.removeAll(finalGraph.vertexSet());
                                currentLevel.clear();
                                currentLevel.addAll(nextLevelVertices);
                                finalGraph.union(adjacentGraph);

                        } else {
                                break;
                        }
                        levelCount++;

                }

                
            try {
                if (outputTime) {
                    final JSONObject graphTimeSpan = new JSONObject();
                    if (graphMaxTime == Double.MIN_VALUE && graphMinTime == Double.MAX_VALUE) {
                        logger.log(Level.INFO, "Charra bc", finalGraph.toString());
                        graphMaxTime = -1.0;
                        graphMinTime = -1.0;
                    } else if (graphMaxTime == Double.MIN_VALUE || graphMinTime == Double.MAX_VALUE) {
                        logger.log(Level.SEVERE, "This shouldn't be happening");
                    }
                    graphTimeSpan.put("start_time", graphMinTime);
                    graphTimeSpan.put("end_time", graphMaxTime);

                    outputWriter.write(graphTimeSpan.toString() + "\n");
                    outputWriter.close();
                }
            }catch (Exception e) {
                logger.log(Level.SEVERE, "Failed to create JSON Object for TemporalTraversalPrime Transformer", e);
            }                
            return finalGraph;
        }

}
