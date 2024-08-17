# GPU_Assignment4

 Problem Statement
 There is a battlefield which can be represented as a grid of size M x N.
 There are ‘T’ no. of tanks placed randomly on the grid with ids (0 to T-1)
 at integer coordinates (x,y). Consider the tanks to be point sized objects.
 Your task is to simulate a game between tanks with following rules and re
turn the score of each tank at the end of the game.
 The rules are as follows:
 • Each tank has Health Points (HP) allotted to them given in an array. A
 tank is considered destroyed at the end of a round if its HP dropped to
 <=0.
 • The game consists of multiple rounds, in each round the tanks which are
 not yet destroyed in the previous rounds fire in the direction of other
 tanks.
 • In kth round the Tank i will fire in the direction of Tank (i+k)%T. Since
 a tank cannot fire at its own direction you can consider every round which
 is a multiple of T to be a null round i.e the tanks do not fire at each other.
 • Each hit taken by a tank reduces its HP by 1 and increase the score of
 the tank which fired that shot by 1.
 • The way hit detection works is that if in a round Tank i fires in the
 direction of Tank j the shot will hit the first tank it encounters in that
 direction which is not yet destroyed. So depending on the layout of the
 grid there can be following scenarios and their logical variations:– The simplest case in which there are no tanks between Tanks i and j
 and Tank j is not destroyed, so the shot hits Tank j.
