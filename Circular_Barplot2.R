# Circular Barplot - grouped and stacked circular barplot
# 26/06/2019


library(tidyverse)


#data<-COUNTs
data<-data.frame(
  individual=as.factor(COUNTs2$Model),
  group=as.factor(COUNTs2$Month), 
  Pos= COUNTs2$Pos,
  NoSign= COUNTs2$NoSign,
  Neg= COUNTs2$Neg
)
names(data)<-c("individual", "group","Pos", "NoSign", "Neg")






# Transform data in a tidy format (long format)
data = data %>% gather(key = "observation", value="value", -c(1,2)) 

# Set a number of 'empty bar' to add at the end of each group
empty_bar=1
nObsType=nlevels(as.factor(data$observation))
to_add = data.frame( matrix(NA, empty_bar*nlevels(data$group)*nObsType, ncol(data)) )
colnames(to_add) = colnames(data)
to_add$group=rep(levels(data$group), each=empty_bar*nObsType )
data=rbind(data, to_add)
data=data %>% arrange(group, individual)
data$id=rep( seq(1, nrow(data)/nObsType) , each=nObsType)

# Get the name and the y position of each label
label_data= data %>% group_by(id, fct_explicit_na(individual)) %>% summarize(tot=sum(value))
names(label_data)<-c("id", "individual", "tot")
number_of_bar=nrow(label_data)
angle= 90 - 360 * (label_data$id-0.5) /number_of_bar     # I substract 0.5 because the letter must have the angle of the center of the bars. Not extreme right(1) or extreme left (0)
label_data$hjust<-ifelse( angle < -90, 1, 0)
label_data$angle<-ifelse(angle < -90, angle+180, angle)

# prepare a data frame for base lines
base_data=data %>% 
  group_by(group) %>% 
  summarize(start=min(id), end=max(id) - empty_bar) %>% 
  rowwise() %>% 
  mutate(title=mean(c(start, end)))
base_data$group1<-month.abb

# prepare a data frame for grid (scales)
grid_data = base_data
grid_data$end = grid_data$end[ c( nrow(grid_data), 1:nrow(grid_data)-1)] + 1
grid_data$start = grid_data$start - 1
grid_data=grid_data[-1,]


colori<-colorRampPalette(c("red","lightgrey","green"))


# Make the plot
p = ggplot(data) +      
  
  # Add the stacked bar
  geom_bar(aes(x=as.factor(id), y=value, fill=observation), stat="identity", alpha=0.5) +
 
  # colori e legenda:
  scale_fill_manual(values=colori(3),labels = c("Increasing Trend", "No Signal", "Decreasing Trend")) +
  
  # Add a val=100/75/50/25 lines. I do it at the beginning to make sur barplots are OVER it.
  geom_segment(data=grid_data, aes(x = end+0.5, y = 0, xend = start-0.5, yend = 0), colour = "grey", alpha=1, size=0.3 , inherit.aes = FALSE ) +
  geom_segment(data=grid_data, aes(x = end+0.5, y = 25, xend = start-0.5, yend = 25), colour = "grey", alpha=1, size=0.3 , inherit.aes = FALSE ) +
  geom_segment(data=grid_data, aes(x = end+0.5, y = 50, xend = start-0.5, yend = 50), colour = "grey", alpha=1, size=0.3 , inherit.aes = FALSE ) +
  geom_segment(data=grid_data, aes(x = end+0.5, y = 75, xend = start-0.5, yend = 75), colour = "grey", alpha=1, size=0.3 , inherit.aes = FALSE ) +
  geom_segment(data=grid_data, aes(x = end+0.5, y = 100, xend = start-0.5, yend = 100), colour = "grey", alpha=1, size=0.3 , inherit.aes = FALSE ) +
  
  # Add text showing the value of each 100/75/50/25 lines
  annotate("text", x = rep(max(data$id),5)+1, y = c(0, 25, 50, 75, 100), label = c("0 %", "25 %", "50 %", "75 %", "100 %") , color="grey", size=4 , angle=0, fontface="bold", hjust=1) +
  
  ylim(-150,max(label_data$tot, na.rm=T)+20) +
  theme_minimal() +
  theme(
    #legend.position = "none",
    legend.position="bottom",legend.title=element_blank(), legend.direction="horizontal",
    axis.text = element_blank(),
    axis.title = element_blank(),
    panel.grid = element_blank(),
    plot.margin = unit(rep(1,4), "cm") 
  ) +
  coord_polar() +
  
  # Add labels on top of each bar
  geom_text(data=label_data, aes(x=id, y=tot+10, label=individual, hjust=hjust), color="black", fontface="bold",alpha=0.6, size=3, angle= label_data$angle, inherit.aes = FALSE ) +
  
  # Add base line information
  geom_segment(data=base_data, aes(x = start, y = -5, xend = end, yend = -5), colour = "black", alpha=0.8, size=0.6 , inherit.aes = FALSE )  +
  geom_text(data=base_data, aes(x = title, y = -18, label=group1), hjust="inward", colour = "black", alpha=0.8, size=4, fontface="bold", inherit.aes = FALSE)


p



