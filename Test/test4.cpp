//DO NOT CHANGE ANYTHING IN THIS FILE

#include <iostream>
#include "Graph.cpp"
using namespace std;

int main()
{
    bool topoSort_passed = true;
    Graph mygraph1("test1.txt", true);
    Graph mygraph2("test2.txt", true);
    Graph mygraph3("test4a.txt", true);
    
    if (mygraph1.topoSort() !="ABDEC" && mygraph1.topoSort() != "ADBEC" && mygraph1.topoSort() != "ADEBC" && mygraph1.topoSort() != "DABEC" && mygraph1.topoSort() != "DEABC")
    {
        topoSort_passed = false;
    }
        
   if (mygraph2.topoSort() != "ACBDEGF" && mygraph2.topoSort() != "ACBDGEF" && mygraph2.topoSort() != "ACBEDGF" && mygraph2.topoSort() !="ACBEGDF" && mygraph2.topoSort() !=  "ACBGDEF" && mygraph2.topoSort() !=  "ACBGEDF" && mygraph2.topoSort() !=  "ACGBDEF" && 
    mygraph2.topoSort() != "ACGBEDF" && mygraph2.topoSort() !=  "AGCBDEF" && mygraph2.topoSort() !=  "AGCBEDF")
    {
        topoSort_passed = false;
    }
        

    if (mygraph3.topoSort() != "ABCDEF" && mygraph3.topoSort() != "ABCEDF" && mygraph3.topoSort() != "ABCEFD" && mygraph3.topoSort() != "ABECDF" && mygraph3.topoSort() != "ABECFD" && mygraph3.topoSort() != "ABEFCD")
    {
        topoSort_passed = false;
    }
    
    if (topoSort_passed)
        cout << "Topological Sort Passed 30/30\n";
    else
        cout << "Topological Sort Failed 0/30\n";
    
    return 0;
}