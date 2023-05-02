//DO NOT CHANGE ANYTHING IN THIS FILE

#include <iostream>
#include "Graph.cpp"
using namespace std;

int main()
{
    bool dijkstra_passed = true;

    Graph mygraph2("test2.txt", false);
    Graph mygraph3("test3.txt", false);
    Graph mygraph4("test4.txt", false);

    if (mygraph2.Dijkstra('A', 'F') != 8)
        dijkstra_passed = false;

    if (mygraph2.Dijkstra('B', 'G') != 7)
        dijkstra_passed = false;

    if (mygraph3.Dijkstra('A', 'H') != 9)
        dijkstra_passed = false;

    if (mygraph3.Dijkstra('E', 'B') != 8)
        dijkstra_passed = false;

    if (mygraph3.Dijkstra('E', 'D') != 7)
        dijkstra_passed = false;

    // adjacent but shorter is two step away
    if (mygraph4.Dijkstra('A', 'C') != 3)
        dijkstra_passed = false;

    // not reachable
    if (mygraph4.Dijkstra('E', 'D') != -1)
        dijkstra_passed = false;

    if (mygraph4.Dijkstra('F', 'D') != 2)
        dijkstra_passed = false;

    if (dijkstra_passed)
        cout << "Shortest Path Test Passed\n";
    else
        cout << "Shortest Path Test Failed\n";
    return 0;
}