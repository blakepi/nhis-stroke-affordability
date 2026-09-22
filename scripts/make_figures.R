## Publication figures for the NHIS stroke affordability manuscript.
## Outputs: manuscript/figures/*.png (300 dpi), *.tiff (300 dpi, LZW) and *.pdf (vector).
suppressPackageStartupMessages({library(data.table);library(ggplot2);library(patchwork);library(scales);library(ragg)})
dir.create("manuscript/figures",recursive=TRUE,showWarnings=FALSE)

## ---- Style ----------------------------------------------------------------
FONT<-"Arial"
INK<-"#1a1a1a"; INK2<-"#4a4a4a"; MUTED<-"#767676"; GRID<-"#e4e4e4"; AXIS<-"#bdbdbd"
BLUE<-"#2a78d6"; ORANGE<-"#eb6834"; BLUE_D<-"#1c5cab"; BLUE_L<-"#b7d3f6"
EN<-"–"
theme_pub<-function(base=9){
  theme_minimal(base_size=base,base_family=FONT)+
    theme(panel.grid.minor=element_blank(),
          panel.grid.major=element_line(colour=GRID,linewidth=.3),
          axis.line.x=element_line(colour=AXIS,linewidth=.4),
          axis.ticks.x=element_line(colour=AXIS,linewidth=.4),
          axis.ticks.length=unit(2,"pt"),
          axis.text=element_text(colour=INK2,size=base-.5),
          axis.title=element_text(colour=INK,size=base),
          legend.text=element_text(size=base-.5,colour=INK2),
          legend.key.height=unit(9,"pt"),legend.key.width=unit(18,"pt"),
          legend.margin=margin(0,0,0,0),
          plot.title.position="plot",
          plot.tag=element_text(face="bold",size=base+2,family=FONT),
          plot.margin=margin(6,10,6,6),
          strip.text=element_text(face="bold",size=base,colour=INK,hjust=0),
          strip.placement="outside")
}
save_fig<-function(p,name,w,h){
  ggsave(sprintf("manuscript/figures/%s.png",name),p,width=w,height=h,units="in",dpi=300,bg="white",device=ragg::agg_png)
  ggsave(sprintf("manuscript/figures/%s.tiff",name),p,width=w,height=h,units="in",dpi=300,bg="white",device=ragg::agg_tiff,compression="lzw")
  ggsave(sprintf("manuscript/figures/%s.pdf",name),p,width=w,height=h,units="in",bg="white",device=cairo_pdf)
}

## ---- Figure 1: annual trend (A, top) and component prevalence (B, bottom) --
annual<-fread("outputs/annual_prevalence.csv")[outcome=="any_barrier" & group=="All survivors"]
adj<-fread("outputs/full/adjusted_annual_prevalence.csv")
a<-rbindlist(list(annual[,.(year,estimate,lower,upper,series="Observed (annual survey weights)")],
                  adj[,.(year,estimate,lower,upper,series="Standardized (fully adjusted model)")]))
a[,series:=factor(series,levels=c("Observed (annual survey weights)","Standardized (fully adjusted model)"))]
pooled<-fread("outputs/full/component_prevalence.csv")[outcome=="any_barrier"]
F1<-11
p1a<-ggplot(a,aes(year,100*estimate,colour=series,shape=series))+
  annotate("rect",xmin=2018.55,xmax=2025.45,ymin=100*pooled$lower,ymax=100*pooled$upper,fill=BLUE_L,alpha=.45)+
  annotate("text",x=2018.6,y=28.8,hjust=0,vjust=1,size=3.7,colour=INK2,family=FONT,
           label=sprintf("Shaded band: pooled 2019%s2025 prevalence, %.1f%% (95%% CI, %.1f%s%.1f)",EN,100*pooled$estimate,100*pooled$lower,EN,100*pooled$upper))+
  geom_line(aes(group=series),linewidth=.9,position=position_dodge(width=.28))+
  geom_errorbar(aes(ymin=100*lower,ymax=100*upper),width=.12,linewidth=.7,position=position_dodge(width=.28))+
  geom_point(size=3.4,position=position_dodge(width=.28),stroke=0)+
  scale_colour_manual(values=c(BLUE_D,ORANGE),name=NULL)+
  scale_shape_manual(values=c(16,17),name=NULL)+
  scale_x_continuous(breaks=2019:2025,expand=expansion(add=.45))+
  scale_y_continuous(limits=c(0,30),breaks=seq(0,30,5),expand=expansion(0))+
  labs(x="Survey year",y="Prevalence of any\ncost-related barrier (%)",tag="A")+
  theme_pub(F1)+theme(panel.grid.major.x=element_blank(),
                      legend.position="top",legend.justification="left",legend.direction="horizontal",legend.box.margin=margin(0,0,4,0),
                      legend.key.width=unit(26,"pt"),legend.text=element_text(size=F1-.5,colour=INK),
                      axis.text=element_text(size=F1-.5,colour=INK2))

comp<-fread("outputs/full/component_prevalence.csv")
lab<-c(any_barrier="Any cost-related barrier",forgone_rx="Could not afford a needed prescription",
       delayed_care="Delayed medical care because of cost",forgone_care="Did not get needed medical care because of cost",
       rx_underuse="Skipped, reduced, or delayed medication to save money*")
comp<-comp[outcome %in% names(lab)]
comp[,label:=factor(lab[outcome],levels=rev(lab))]
comp[,fill:=ifelse(outcome=="any_barrier",BLUE_D,BLUE)]
p1b<-ggplot(comp,aes(100*estimate,label))+
  geom_col(aes(fill=fill),width=.62)+
  geom_errorbar(aes(xmin=100*lower,xmax=100*upper),width=.22,linewidth=.6,colour=INK)+
  geom_text(aes(x=100*upper+.5,label=sprintf("%.1f%%",100*estimate)),hjust=0,size=3.9,colour=INK,family=FONT)+
  scale_fill_identity()+
  scale_x_continuous(limits=c(0,25),breaks=seq(0,20,5),expand=expansion(0))+
  labs(x=sprintf("Pooled prevalence, 2019%s2025 (%%)",EN),y=NULL,tag="B",
       caption="*Among survivors prescribed medication in the past 12 months.")+
  theme_pub(F1)+theme(panel.grid.major.y=element_blank(),axis.text.y=element_text(colour=INK,size=F1-.5),
                      axis.text.x=element_text(size=F1-.5,colour=INK2),
                      plot.caption=element_text(size=F1-1.5,colour=INK2,hjust=0),plot.caption.position="plot")
fig1<-free(p1a)/p1b+plot_layout(heights=c(1.15,1))
save_fig(fig1,"figure1_annual_prevalence",7,7.4)

## ---- Figure 2: subgroup prevalence (A) aligned with adjusted PRs (B) -------
sg<-fread("outputs/full/subgroup_prevalence.csv")
co<-fread("outputs/full/model_coefficients.csv")
rows<-data.table(
  group=c("Age","Age","Family income (% FPL)","Family income (% FPL)","Family income (% FPL)","Family income (% FPL)",
          "Insurance","Insurance","Insurance","Insurance","Disability","Disability"),
  variable=c("young","young","income_group","income_group","income_group","income_group",
             "insurance","insurance","insurance","insurance","disability","disability"),
  level=c("65+","18-64","400%+","200-399%","100-199%","<100%","Private","Public without private","Military only","Uninsured","Without disability","With disability"),
  label=c("65 years or older (ref)",paste0("18",EN,"64 years"),"≥400% (ref)",paste0("200",EN,"399%"),paste0("100",EN,"199%"),"<100%",
          "Private (ref)","Public, no private","Military only","Uninsured","No disability (ref)","Disability"),
  model=c("Age_M3","Age_M3","M3","M3","M3","M3","M3","M3","M3","M3","M3","M3"),
  term=c(NA,"young18-64",NA,"income_group200-399%","income_group100-199%","income_group<100%",
         NA,"insurancePublic without private","insuranceMilitary only","insuranceUninsured",NA,"disabilityWith disability"))
rows[,order:=.I]
d<-merge(rows,sg[,.(variable,level,n=n_mean,estimate,lower,upper)],by=c("variable","level"),all.x=TRUE)
d<-merge(d,co[,.(model,term,PR,lower_pr=lower,upper_pr=upper)],by=c("model","term"),all.x=TRUE)
setorder(d,order)
d[is.na(term),`:=`(PR=1,lower_pr=NA_real_,upper_pr=NA_real_)]
d[,label:=factor(label,levels=rev(label))]
d[,group:=factor(group,levels=unique(rows$group))]
d[,ref:=is.na(term)]
d[,pr_text:=ifelse(ref,"1 (reference)",sprintf("%.2f (%.2f%s%.2f)",PR,lower_pr,EN,upper_pr))]
d[,prev_text:=sprintf("%.1f (%.1f%s%.1f)",100*estimate,100*lower,EN,100*upper)]

p2a<-ggplot(d,aes(100*estimate,label))+
  geom_segment(aes(x=0,xend=100*estimate,yend=label),colour=BLUE_L,linewidth=2.6,lineend="butt")+
  geom_errorbar(aes(xmin=100*lower,xmax=100*upper),width=0,linewidth=.5,colour=INK)+
  geom_point(size=2.2,colour=BLUE_D)+
  geom_text(aes(x=72,label=prev_text),hjust=0,size=2.6,colour=INK2,family=FONT)+
  facet_grid(rows=vars(group),scales="free_y",space="free_y",switch="y")+
  scale_x_continuous(limits=c(0,100),breaks=seq(0,60,20),expand=expansion(0))+
  coord_cartesian(clip="off")+
  labs(x="Prevalence, % (95% CI)",y=NULL,tag="A")+
  theme_pub()+theme(panel.grid.major.y=element_blank(),strip.text.y.left=element_text(angle=0,hjust=1,vjust=1),
                    panel.spacing.y=unit(6,"pt"),axis.text.y=element_text(colour=INK,size=8.5),axis.title.x=element_text(hjust=0))

p2b<-ggplot(d,aes(PR,label))+
  geom_vline(xintercept=1,linetype="22",colour=MUTED,linewidth=.4)+
  geom_errorbar(aes(xmin=lower_pr,xmax=upper_pr),width=0,linewidth=.5,colour=INK,na.rm=TRUE)+
  geom_point(aes(shape=ref,fill=ref),size=2.4,colour=BLUE_D)+
  geom_text(aes(x=4.2,label=pr_text),hjust=0,size=2.6,colour=INK2,family=FONT)+
  scale_shape_manual(values=c(`FALSE`=21,`TRUE`=23),guide="none")+
  scale_fill_manual(values=c(`FALSE`=BLUE_D,`TRUE`="white"),guide="none")+
  facet_grid(rows=vars(group),scales="free_y",space="free_y")+
  scale_x_log10(limits=c(.45,40),breaks=c(.5,1,2,3),labels=c("0.5","1","2","3"),expand=expansion(0))+
  coord_cartesian(clip="off")+
  labs(x="Adjusted PR (95% CI), log scale",y=NULL,tag="B")+
  theme_pub()+theme(panel.grid.major.y=element_blank(),strip.text=element_blank(),
                    axis.text.y=element_blank(),panel.spacing.y=unit(6,"pt"),axis.title.x=element_text(hjust=0))
fig2<-p2a+p2b+plot_layout(widths=c(1.25,1))
save_fig(fig2,"figure2_adjusted_associations",7.3,4.6)

## ---- Figure S1: sample selection flow --------------------------------------
box<-function(x,y,w,h,text,fill="white",col=INK,size=2.9,face="plain"){
  list(annotate("rect",xmin=x-w/2,xmax=x+w/2,ymin=y-h/2,ymax=y+h/2,fill=fill,colour=AXIS,linewidth=.4),
       annotate("text",x=x,y=y,label=text,size=size,colour=col,family=FONT,lineheight=.95,fontface=face))
}
arrow<-function(x1,y1,x2,y2){annotate("segment",x=x1,y=y1,xend=x2,yend=y2,colour=INK2,linewidth=.45,
                                     arrow=grid::arrow(length=unit(4,"pt"),type="closed"))}
ps1<-ggplot()+
  box(0,10,5.6,1.15,sprintf("207,064 Sample Adult records\nNHIS 2019%s2025 annual files",EN),fill="#f3f6fa",face="bold")+
  arrow(0,9.42,0,8.78)+
  box(0,8.2,5.6,1.15,"7,565 adults reporting a prior stroke",fill="#f3f6fa")+
  box(4.75,8.2,2.9,.85,"10 excluded:\nunknown age",size=2.6,col=INK2)+
  annotate("segment",x=2.8,y=8.2,xend=3.3,yend=8.2,colour=INK2,linewidth=.45)+
  arrow(0,7.62,0,6.98)+
  box(0,6.4,5.6,1.15,"7,555 age-eligible stroke survivors\n(annual analyses; 7,476 with observed outcome)",fill="#f3f6fa")+
  annotate("segment",x=0,y=5.82,xend=0,yend=5.45,colour=INK2,linewidth=.45)+
  annotate("segment",x=-2.4,y=5.45,xend=2.4,yend=5.45,colour=INK2,linewidth=.45)+
  arrow(-2.4,5.45,-2.4,4.95)+arrow(2.4,5.45,2.4,4.95)+
  box(-2.4,4.3,4.4,1.25,"Annual estimates\nFull 2020 sample, annual weights\n(Figure 1A, Table 2)",fill="white")+
  box(2.4,4.3,4.4,1.25,"Pooled estimates\n2020 follow-back respondents removed;\npartial-sample weights",fill="white")+
  arrow(2.4,3.67,2.4,3.05)+
  box(2.4,2.5,4.4,1.05,"7,181 pooled stroke survivors\n7,104 with observed outcome (1,184 with a barrier)",fill="#f3f6fa")+
  box(-2.6,2.5,3.6,.85,"327 excluded from models:\nmissing adjustment covariate",size=2.6,col=INK2)+
  annotate("segment",x=-0.8,y=2.5,xend=0.2,yend=2.5,colour=INK2,linewidth=.45)+
  arrow(2.4,1.97,2.4,1.35)+
  box(2.4,.8,4.4,1.05,"6,777 in adjusted models\n1,117 with a barrier",fill="#f3f6fa",face="bold")+
  coord_cartesian(xlim=c(-4.8,6.4),ylim=c(.2,10.65),expand=FALSE)+theme_void()+theme(plot.margin=margin(4,4,4,4))
save_fig(ps1,"figureS1_cohort_flow",6.2,6.6)
cat("figures written\n")
