%sst_overview_areas

isl_lat = [70 60 60 70 70]
isl_lon =[-10 -10 -30 -30 -10];

S_lat = [65 60 60 65 65]
S_lon =[-20 -20 -30 -30 -20];

N_lat = [70 65 65 70 70]
N_lon =[-10 -10 -20 -20 -10];

[70 65],[-20 -30]

W_lat = [70 65 65 70 70]
W_lon =[-20 -20 -30 -30 -20];

E_lat = [65 60 60 65 65]
E_lon =[-10 -10 -20 -20 -10];

CB_lat = [56 50 50 56 56]
CB_lon =[-33 -33 -39 -39 -33];

clines = lines(5);

geoplot(isl_lat,isl_lon,"ko", 'MarkerSize',8,'MarkerFaceColor','k',...
    'DisplayName','Ísland')
hold on
geoplot(S_lat,S_lon,'LineWidth',2,'Color',clines(1,:),'DisplayName','Ísland - Suður')
hold on
geoplot(N_lat,N_lon,'LineWidth',2,'Color',clines(2,:),'DisplayName','Ísland - Norður')
hold on
geoplot(W_lat,W_lon,'LineWidth',2,'Color',clines(3,:),'DisplayName','Ísland - Vestur')
hold on
geoplot(E_lat,E_lon,'LineWidth',2,'Color',clines(4,:),'DisplayName','Ísland - Austur')
hold on
geoplot(CB_lat,CB_lon,'LineWidth',2,'Color',clines(5,:),'DisplayName','Ísland - Kaldi blettur')

legend show

exportgraphics(gcf,'sst_overview_areas.pdf');
exportgraphics(gcf,'sst_overview_areas.png');
 