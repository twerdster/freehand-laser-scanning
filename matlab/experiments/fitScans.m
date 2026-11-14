fileName = 'groundTruthSubsample.ply' ;
[vertex1 ,~]= read_ply(fileName);
fileName = 'laserScan.ply' ;
[vertex2 ,~]= read_ply(fileName);
Options.Registration = 'Size';
Options.Verbose = true;
Options.TolP = 0.00001;
[Points_Moved,M] = ICP_finite(vertex1, vertex2, Options);

plot3(Points_Moved(:,1),Points_Moved(:,2),Points_Moved(:,3),'.r')
hold on
plot3(vertex1(:,1),vertex1(:,2),vertex1(:,3),'.g')

