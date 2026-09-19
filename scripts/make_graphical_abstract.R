## Graphic abstract for Stroke: single panel, 7 x 7 in, 12-pt sans-serif, graphical content only.
suppressPackageStartupMessages({library(data.table);library(ggplot2);library(patchwork);library(ragg)})
FONT<-"Arial"; INK<-"#1a1a1a"; INK2<-"#4a4a4a"; GRID<-"#e4e4e4"
BLUE<-"#2a78d6"; BLUE_D<-"#1c5cab"; BLUE_L<-"#cde2fb"; ORANGE<-"#eb6834"; EN<-"–"
comp<-fread("outputs/full/component_prevalence.csv")[outcome=="any_barrier"]
sg<-fread("outputs/full/subgroup_prevalence.csv")
annual<-fread("outputs/annual_prevalence.csv")[outcome=="any_barrier" & group=="All survivors"]
pct<-function(v,l) 100*sg[variable==v & level==l,estimate]
base<-theme_void(base_family=FONT)+theme(plot.margin=margin(4,4,4,4))

## Panel 1: waffle, 1 in 6
n<-round(100*comp$estimate)
w<-data.table(expand.grid(x=1:10,y=1:10));w[,i:=.I];w[,hit:=i<=n]
p1<-ggplot(w,aes(x,y))+geom_tile(aes(fill=hit),width=.82,height=.82)+
  scale_fill_manual(values=c(`TRUE`=ORANGE,`FALSE`=BLUE_L),guide="none")+coord_equal()+base+
  labs(title=sprintf("%d%% of US stroke survivors\ncould not afford care or\nmedications in the past year",n))+
  theme(plot.title=element_text(size=12,family=FONT,colour=INK,lineheight=1.05,hjust=0,margin=margin(b=6)))

## Panel 2: who is affected (bars)
d<-data.table(label=c("Ages 18–64","Ages 65+","Uninsured","Privately insured","Income <200% FPL","Income ≥400% FPL"),
              v=c(pct("young","18-64"),pct("young","65+"),pct("insurance","Uninsured"),pct("insurance","Private"),
                  mean(c(pct("income_group","100-199%"),pct("income_group","<100%"))),pct("income_group","400%+")))
d[,label:=factor(label,levels=rev(label))]
p2<-ggplot(d,aes(v,label))+geom_col(fill=BLUE,width=.62)+
  geom_text(aes(label=sprintf("%.0f%%",v)),hjust=-.15,size=4.2,family=FONT,colour=INK)+
  scale_x_continuous(limits=c(0,75),expand=expansion(0))+
  theme_minimal(base_family=FONT,base_size=12)+
  theme(panel.grid=element_blank(),axis.title=element_blank(),axis.text.x=element_blank(),
        axis.text.y=element_text(size=12,colour=INK),plot.title=element_text(size=12,colour=INK,hjust=0,margin=margin(b=6)),
        plot.margin=margin(4,10,4,4))+
  labs(title="Highest among working-age,\nuninsured, and lower-income\nsurvivors")

## Panel 3: flat trend
p3<-ggplot(annual,aes(year,100*estimate))+
  annotate("rect",xmin=2018.6,xmax=2025.4,ymin=100*comp$lower,ymax=100*comp$upper,fill=BLUE_L,alpha=.5)+
  geom_line(colour=BLUE_D,linewidth=1)+geom_point(colour=BLUE_D,size=2.6)+
  scale_x_continuous(breaks=c(2019,2022,2025))+scale_y_continuous(limits=c(0,30),breaks=c(0,10,20,30),expand=expansion(0))+
  theme_minimal(base_family=FONT,base_size=12)+
  theme(panel.grid.minor=element_blank(),panel.grid.major=element_line(colour=GRID,linewidth=.3),
        axis.title=element_blank(),axis.text=element_text(size=12,colour=INK2),
        plot.title=element_text(size=12,colour=INK,hjust=0,margin=margin(b=6)),plot.margin=margin(4,10,4,4))+
  labs(title="No improvement across 2019–2025\n(prevalence, %)")

## Panel 4: implication
p4<-ggplot()+annotate("rect",xmin=0,xmax=1,ymin=0,ymax=1,fill="#f3f6fa",colour=NA)+
  annotate("text",x=.06,y=.5,hjust=0,vjust=.5,size=4.3,family=FONT,colour=INK,lineheight=1.1,
           label="Implication\n\nAsk stroke survivors about\ncost at every follow-up,\nespecially those younger\nthan 65, uninsured, or\nof lower income, and\nconnect them to assistance\nbefore treatment lapses.")+
  coord_cartesian(xlim=c(0,1),ylim=c(0,1),expand=FALSE)+base

title<-ggplot()+annotate("text",x=0,y=.62,hjust=0,vjust=.5,size=4.6,fontface="bold",family=FONT,colour=INK,lineheight=1,
  label="Cost-related barriers to care and medications
among US stroke survivors, NHIS 2019–2025")+
  annotate("text",x=0,y=0,hjust=0,vjust=0,size=4.2,family=FONT,colour=INK2,
  label="Nationally representative survey of 7,104 adults reporting a prior stroke")+
  coord_cartesian(xlim=c(0,1),ylim=c(-.1,1),expand=FALSE)+base
ga<-title/((p1|p2)/(p3|p4))+plot_layout(heights=c(.17,1))
ggsave("manuscript/figures/graphic_abstract.jpg",ga,width=7,height=7,units="in",dpi=300,bg="white",device=ragg::agg_jpeg,quality=95)
ggsave("manuscript/figures/graphic_abstract.png",ga,width=7,height=7,units="in",dpi=150,bg="white",device=ragg::agg_png)
cat("graphic abstract written\n")
