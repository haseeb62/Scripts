def read_file(file):
    graphs = []
    with open(file, 'r') as f:
        counter = 0
        for line in f:
            start_time, end_time = map(int, line.strip().split())
            graphs.append((counter,start_time, end_time))
            counter +=1 
            
            
    # print(graphs)
    return graphs

def find_overlapping_graphs4(graphs):
    n = len(graphs)
    # print(graphs[0])
    output = {}
    for i in range(0,n):
        temp = []
        for j in range(i+1,n):
            if graphs[i][2] < graphs[j][1]: #ending time is less than starting time
                output[graphs[i][0]] = temp
                break
            elif graphs[i][1] == graphs[j][1]: #start times of both are same
                temp.append(graphs[j][0])
            elif graphs[j][2] > graphs[i][2]: #start time and end time of 2nd graph is greater
                continue
            else:
                temp.append(graphs[j][0])
                

    print("Graph Intersections: ", output)

graphs = read_file("time.txt")
import operator
print(graphs)
print("\n\n\n\n\n")
s = sorted(graphs, key = operator.itemgetter(1, 2))
print(s)
j = find_overlapping_graphs4(s)





