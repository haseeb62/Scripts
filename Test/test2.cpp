//DO NOT CHANGE ANYTHING IN THIS FILE

#include <iostream>
#include "Graph.cpp"
using namespace std;

int main()
{
    bool reach_passed = true;
    Graph mygraph1("test1.txt",false);
    Graph mygraph2("test2.txt",false);
    Graph mygraph4("test4.txt",false);

    // testing reachable 1 (yes)
    if (!mygraph1.Reachable('A', 'D'))
        reach_passed = false;
    // testing reachable 2 (yes)
    if (!mygraph4.Reachable('E', 'B'))
        reach_passed = false;

    // testing reachable 3 (no)
    if (mygraph4.Reachable('A', 'F'))
        reach_passed = false;

    // testing reachable 4 (yes)
    if (!mygraph4.Reachable('D', 'F'))
        reach_passed = false;

    // testing reachable 3 (no)
    if (mygraph4.Reachable('B', 'D'))
        reach_passed = false;

    // testing reachable 5 (yes)
    if (!mygraph2.Reachable('A', 'F'))
        reach_passed = false;

    // testing reachable 6 (yes)
    if (!mygraph2.Reachable('D', 'A'))
        reach_passed = false;

    // testing reachable 7 (yes)
    if (!mygraph2.Reachable('E', 'A'))
        reach_passed = false;

    if (reach_passed)
        cout << "Reachable Test Passed\n";
    else
        cout << "Reachable Test Failed\n";
}