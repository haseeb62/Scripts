package spade.filter;

import spade.core.AbstractEdge;
import spade.core.AbstractFilter;
import spade.core.AbstractVertex;

public class DropAgents extends AbstractFilter{
    private final String agentType = "Principal";
    private final String agentEdgeType = "Edge";

    @Override
        public void putVertex(AbstractVertex vertex){
        final String vertexType = vertex.getAnnotation("type");
                if(vertex == null || agentType.equals(vertexType)){
                        return;
        }
                putInNextFilter(vertex);
        }
    //In CDM data type: Edge is only ever used for Agent vertex edges
        @Override
        public void putEdge(AbstractEdge edge){
                if(edge == null || edge.getChildVertex() == null || edge.getParentVertex() == null){
                        return;
                }
                if(agentEdgeType.equals(edge.getAnnotation("type"))){
                        return;
                }
        putInNextFilter(edge);
    }
}
