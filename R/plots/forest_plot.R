library(forestplot)
library("tools")
library("rstudioapi")
# library(dplyr)
setwd(dirname(getActiveDocumentContext()$path))
setwd('../../')


df_final <- read.csv(
    './data/summarized/temporal/conceptWAS-logistf-covid_vs_all-by_0527_to_week12.csv',
    header = TRUE, row.names = 1, stringsAsFactors=FALSE
  )

#calculate the prevlance
df_final['preva_in_cases' ] <- df_final['n_cui_in_cases']/df_final['n_cases']
df_final['preva_in_controls' ] <- df_final['n_cui_in_controls']/df_final['n_controls']
df_final$preva_in_case = sprintf("%.1f%%", 100*df_final$preva_in_case)
df_final$preva_in_controls = sprintf("%.1f%%", 100*df_final$preva_in_controls)

df_final['case_cnt'] = paste0(df_final$n_cui_in_cases, ' (', df_final$preva_in_case,')')
df_final['control_cnt'] = paste0(df_final$n_cui_in_controls, ' (', df_final$preva_in_controls,')')

#select the top signals that cross the siginicant level and related to symptoms

top_signals = c('c11570_pos', 'c13604_pos', 'c15967_neg', 'c3467_pos', 'c3126_pos', 
                'c1880200_pos', 'c586120_pos', 'c15967_pos', 'c1277295_pos', 'c43144_pos',
                'c337671_pos', 'c2364111_pos', 'c36572_pos')
d <- df_final[top_signals, ]

d$cui_name = toTitleCase(tolower(d$cui_name))
d['c15967_neg', ]$cui_name = paste0(d['c15967_neg', ]$cui_name, '(negated)')
d['c586120_pos', ]$cui_name = "Smoking Monitoring Status"
cochrane_from_rmeta <- d[, c('odds_ratio', 'lower_CI', 'upper_CI')]
cochrane_from_rmeta <-rbind(c(NA, NA, NA), cochrane_from_rmeta)


#side table
tabletext <- d[, c('cui_name' ,'case_cnt', 'control_cnt'
                   #, 'p_value', 'odds_ratio'
                   )]
# tabletext$odds_ratio<-sprintf("%.2f", tabletext$odds_ratio)
tabletext <- rbind(c("Concept Name", "COVID+ (%)", "COVID- (%)" #, "P-value",  "OR"
                     ), tabletext)


# svg(file = './images/forest_plot_0924.svg') 
# tiff("./images/forest_plot_0924.tiff", width = 4, height = 4, units = 'in', res = 300)
png("./images/forest_plot_0924.png", width=2060, height=1440, res=150)
forestplot(tabletext, cochrane_from_rmeta ,new_page = TRUE,
                      hrzl_lines = list("2" = gpar(lty=1)),
                      is.summary=FALSE,
                      clip=c(0.1,Inf), 
                      xlog=TRUE, graphwidth=unit(0.36, "npc"), #graphwidth
                      txt_gp = fpTxtGp(label = gpar(fontfamily='Helvetica', cex = 1.5),
                                       ticks = gpar(fontfamily = "Helvetica", cex=1.5),
                                       xlab  = gpar(fontfamily = "Helvetica", cex = 1.5)),
                      xlab='OR (95%CI)', 
                      line.height= unit(0.1, "npc"),   line.margin = unit(0.02, "npc"),
                      col=fpColors(box="royalblue",line="darkblue")) 

dev.off()
