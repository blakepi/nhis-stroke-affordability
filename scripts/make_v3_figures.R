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

## Figure 1: NHIS (hypothesis-generating) and MEPS (registered) estimates for H1 and H2
if(mode=="real"){
 mc<-fread("outputs/meps/real/confirmatory_runs.csv");mx<-fread("outputs/meps/real/exploratory_and_sensitivity.csv")
 mb<-fread("outputs/meps/real/bounded_logistic_marginal_PR.csv");fd<-fread("outputs/extended/E12_fdr_family.csv")
 nh<-function(c,lab,panel){r<-fd[contrast==c];stopifnot(nrow(r)==1);data.table(panel=panel,label=lab,PR=r$estimate,lo=r$lower,hi=r$upper,src="NHIS 2019–2025 (hypothesis generating)")}
 mh<-function(h,lab,panel,src="MEPS 2019–2024: registered test"){r<-mc[hypothesis==h];data.table(panel=panel,label=lab,PR=r$PR,lo=r$lower,hi=r$upper,src=src)}
 ms<-function(a,t,lab,panel){r<-mx[analysis==a & term==t];stopifnot(nrow(r)==1);data.table(panel=panel,label=lab,PR=r$PR,lo=r$lower,hi=r$upper,src="MEPS 2019–2024: sensitivity or secondary")}
 mbl<-function(h,lab,panel){r<-mb[hypothesis==h];data.table(panel=panel,label=lab,PR=r$marginal_PR,lo=r$lower,hi=r$upper,src="MEPS 2019–2024: sensitivity or secondary")}
 A<-"A. Medicaid-type vs private coverage and any cost barrier (H1)";B<-"B. Cost barriers and lipid-lowering therapy (H2)"
 f1<-rbind(
  nh("18-64: cover_u65Medicaid and other public","NHIS, 18–64 y: Medicaid or other public",A),
  nh("65+: cover_65Dual eligible","NHIS, ≥65 y: dual Medicare-Medicaid",A),
  mh("H1","MEPS H1: Medicaid-type, both age groups",A),
  ms("H1 age-specific 18-64","medicaid_type","MEPS, 18–64 y",A),ms("H1 age-specific 65+","medicaid_type","MEPS, ≥65 y (dual)",A),
  ms("H1 excluding 2020","medicaid_type","MEPS, excluding 2020",A),ms("H1 same coverage all year","mt_stable","MEPS, same coverage all year",A),
  mbl("H1","MEPS, bounded logistic",A),
  nh("chol_nonuse: any_barrier (Full + any barrier)","NHIS: any barrier, not taking cholesterol drug",B),
  nh("chol_nonuse: care_barrier (Full + care and medication barriers)","NHIS: care barrier (joint model)",B),
  nh("chol_nonuse: rx_barrier (Full + care and medication barriers)","NHIS: medication barrier (joint model)",B),
  mh("H2","MEPS H2: any barrier, no LDL-lowering fill",B),
  ms("H2 joint: care barrier","care_barrier","MEPS: care barrier (joint model)",B),ms("H2 joint: medication barrier","rx_barrier","MEPS: medication barrier (joint model)",B),
  ms("H2 excluding 2020","any_barrier","MEPS, excluding 2020",B),mbl("H2","MEPS, bounded logistic",B),
  mh("Negative control (dental barrier)","MEPS negative control: dental care unaffordable",B,src="MEPS 2019–2024: negative control"))
 f1[,src:=c("NHIS 2019–2025 (hypothesis generating)"="NHIS, hypothesis generating","MEPS 2019–2024: registered test"="MEPS, registered test",
            "MEPS 2019–2024: sensitivity or secondary"="MEPS, sensitivity or secondary","MEPS 2019–2024: negative control"="MEPS, negative control")[src]]
 f1[,key:=paste(panel,label,sep="||")];f1[,key:=factor(key,levels=rev(key))];f1[,panel:=factor(panel,levels=c(A,B))]
 f1[,txt:=sprintf("%.2f (%.2f–%.2f)",PR,lo,hi)]
 S<-c("NHIS, hypothesis generating","MEPS, registered test","MEPS, sensitivity or secondary","MEPS, negative control")
 cols<-setNames(c(GREY,BLUE_D,"#6b9bd6",ORANGE),S);shp<-setNames(c(16,18,1,17),S);siz<-setNames(c(1.8,3.4,1.8,2),S)
 p1<-ggplot(f1,aes(PR,key,colour=src,shape=src))+geom_vline(xintercept=1,colour=AXIS,linewidth=.4)+
  geom_linerange(aes(xmin=lo,xmax=hi),linewidth=.55)+geom_point(aes(size=src))+
  geom_text(aes(x=7,label=txt),colour=INK,hjust=1,size=2.7,family=FONT,show.legend=FALSE)+
  facet_wrap(~panel,ncol=1,scales="free_y")+scale_y_discrete(labels=function(x)sub("^.*\\|\\|","",x))+
  scale_x_log10(breaks=c(.25,.5,1,2),labels=c("0.25","0.5","1","2"),limits=c(.25,7))+
  scale_colour_manual(values=cols,breaks=S,name=NULL)+scale_shape_manual(values=shp,breaks=S,name=NULL)+scale_size_manual(values=siz,breaks=S,name=NULL)+
  guides(colour=guide_legend(nrow=2),shape=guide_legend(nrow=2),size=guide_legend(nrow=2))+
  labs(x="Adjusted prevalence ratio (log scale)",y=NULL)+theme_pub()+
  theme(panel.grid.major.y=element_blank(),axis.text.y=element_text(colour=INK,size=8.5),legend.position="bottom",legend.justification="center")
 save_fig(p1,"figure1_replication",7.2,6.2)
}

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
