## Figures for the three-survey manuscript (Stroke submission). Style follows make_figures.R / make_revision_figures.R.
## Usage: Rscript scripts/make_v3_figures.R [did_mode]   (did_mode defaults to "real"; "synthetic" for a layout check)
## Inputs: outputs/brfss/did_<mode>/event_study.csv; outputs/brfss/rd_real/{binned_means,local_linear_fits,confirmatory_runs}.csv;
##         outputs/meps/real/confirmatory_runs.csv; outputs/extended/E3_coverage_PR.csv.
## Output: manuscript/v3/figures/ (PNG, TIFF 300 dpi, PDF)
suppressPackageStartupMessages({library(data.table);library(ggplot2);library(scales);library(ragg)})
args<-commandArgs(trailingOnly=TRUE);mode<-if(length(args))args[1] else "real"
DEST<-"manuscript/v3/figures";dir.create(DEST,recursive=TRUE,showWarnings=FALSE)
FONT<-"Arial";INK<-"#1a1a1a";INK2<-"#4a4a4a";GRID<-"#e4e4e4";AXIS<-"#bdbdbd";BLUE_D<-"#1c5cab";ORANGE<-"#eb6834";GREY<-"#8a8a8a"
theme_pub<-function(base=10){
 theme_minimal(base_size=base,base_family=FONT)+
  theme(panel.grid.minor=element_blank(),panel.grid.major=element_line(colour=GRID,linewidth=.3),
        axis.line.x=element_line(colour=AXIS,linewidth=.4),axis.ticks.x=element_line(colour=AXIS,linewidth=.4),axis.ticks.length=unit(2,"pt"),
        axis.text=element_text(colour=INK2,size=base-.5),axis.title=element_text(colour=INK,size=base),
        legend.text=element_text(size=base-.5,colour=INK),legend.position="top",legend.justification="left",legend.margin=margin(0,0,0,0),
        plot.margin=margin(6,10,6,6),strip.text=element_text(face="bold",size=base,colour=INK,hjust=0),panel.spacing=unit(14,"pt"))
}
save_fig<-function(p,name,w,h){
 ggsave(sprintf("%s/%s.png",DEST,name),p,width=w,height=h,units="in",dpi=300,bg="white",device=ragg::agg_png)
 ggsave(sprintf("%s/%s.tiff",DEST,name),p,width=w,height=h,units="in",dpi=300,bg="white",device=ragg::agg_tiff,compression="lzw")
 ggsave(sprintf("%s/%s.pdf",DEST,name),p,width=w,height=h,units="in",bg="white",device=cairo_pdf)
}
LAB<-c("H3 uninsured"="A. Uninsured","H4 cost barrier"="B. Could not see a doctor because of cost",
       uninsured="A. Uninsured",cost_barrier="B. Could not see a doctor because of cost")

## Event study (Medicaid expansion, BRFSS 2011-2019)
es<-fread(sprintf("outputs/brfss/did_%s/event_study.csv",mode))
es[,`:=`(panel=factor(LAB[analysis],levels=unique(LAB[c("H3 uninsured","H4 cost barrier")])),lo=100*(ATT-1.96*se),hi=100*(ATT+1.96*se),est=100*ATT,
         period=fifelse(event_time<0,"Before expansion","After expansion"))]
es[event_time==-1,`:=`(lo=0,hi=0)]
p2<-ggplot(es,aes(event_time,est,colour=period))+
 geom_hline(yintercept=0,colour=AXIS,linewidth=.4)+geom_vline(xintercept=-.5,colour=GREY,linewidth=.4,linetype="22")+
 geom_linerange(aes(ymin=lo,ymax=hi),linewidth=.6,na.rm=TRUE)+geom_point(size=1.9)+
 facet_wrap(~panel,ncol=2)+scale_x_continuous(breaks=-3:5,labels=function(x)gsub("-","−",x))+scale_y_continuous(labels=function(x)gsub("-","−",x))+
 scale_colour_manual(values=c("Before expansion"=GREY,"After expansion"=BLUE_D),breaks=c("Before expansion","After expansion"),name=NULL)+
 labs(x="Years since Medicaid expansion",y="Effect, percentage points")+theme_pub()
save_fig(p2,"figure2_event_study",7,3.3)

## Age-65 discontinuity (exploratory; BRFSS 2013-2025)
if(mode=="real" && file.exists("outputs/brfss/rd_real/binned_means.csv")){
 # Binned means only: the interval-minimizing bandwidth is about 2 years, so fitted lines would rest on two ages per side.
 # Each panel states the honest RD estimate instead.
 b<-fread("outputs/brfss/rd_real/binned_means.csv");r<-fread("outputs/brfss/rd_real/confirmatory_runs.csv")
 b[,`:=`(panel=factor(LAB[outcome],levels=LAB[c("uninsured","cost_barrier")]),est=100*mean,lo=100*(mean-1.96*se),hi=100*(mean+1.96*se),side=fifelse(age>=65,"65 or older","Under 65"))]
 pm<-function(x)gsub("-","−",sprintf("%.1f",x))
 r[,`:=`(panel=factor(LAB[outcome],levels=LAB[c("uninsured","cost_barrier")]),
         label=sprintf("Change at 65: %s points\n(honest 95%% CI, %s to %s)",pm(100*estimate),pm(100*lower),pm(100*upper)))]
 r[,ypos:=b[,.(y=0.72*max(hi)),by=panel][match(r$panel,panel),y]]
 p3<-ggplot(b,aes(age,est,colour=side))+geom_vline(xintercept=64.5,colour=GREY,linewidth=.4,linetype="22")+
  geom_linerange(aes(ymin=lo,ymax=hi),linewidth=.45)+geom_point(size=1.7)+
  geom_text(data=r,aes(x=65.8,y=ypos,label=label),inherit.aes=FALSE,hjust=0,vjust=1,size=2.6,family=FONT,colour=INK,lineheight=.95)+
  scale_colour_manual(values=c("Under 65"=GREY,"65 or older"=BLUE_D),guide="none")+
  facet_wrap(~panel,ncol=2,scales="free_y")+scale_x_continuous(breaks=seq(55,75,5))+scale_y_continuous(limits=c(0,NA),expand=expansion(mult=c(0,.05)))+
  labs(x="Age, years",y="Stroke survivors, %")+theme_pub()
 save_fig(p3,"figure3_age65",7,3.2)
}
cat("Figures written to",DEST,"\n")
