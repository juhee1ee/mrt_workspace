###################################
#         Hotel Listly            #
#         Upload URL              #
###################################

library(readr)
library(httr)
library(rvest)
library(openssl)
library(stringr)
library(RCurl)
library(DBI)
library(RSelenium)
library(data.table)
library(dplyr)
library(googlesheets4)
library(lubridate)
library(bigrquery)
library(gargle)
setwd("/home/juheelee/R/hotel/domestic")
source("./db_conn/db_conn.R")
source("./listly/listly_functions.R")
source("./manipulate/m_functions.R")  # Create_url



# group id 정보
listly_info <- fread("./listly/listly_info.csv")
listly_info <- as.data.frame(listly_info)

port_no <- 4480L  # 4480L Firefox

l_type <- "hotel_detail_group"
curr_group <- listly_info %>% filter(listly_type == l_type) %>% 
  filter(group == 1)



# Listly Info
listly_type <- curr_group$listly_type
group_id <- "wulToaQn" # Hotel Group ID : hotel_detail_group

# Open Remote Driver
remDr <- remoteDriver(port = port_no)
remDr$open()
# Login to Listly
loginListly(listly_type)
# Go to the international automation group
navigateGroup(group_id)
Sys.sleep(1)



# listy 그룹 정보
gs4_deauth()
key <- "BDt5IaQMl0kpz92cFqtXf9aC0g2FTYNp" # "BDt5IaQMl0kpz92cFqtXf9aC0g2FTYNp" #listy token
url <- "https://www.listly.io/api/group?key=wulToaQn&arrange=y&href=n&stack=vertical&file=csv" 
#"https://www.listly.io/api/group?key=WNdnzQ7X&arrange=y&href=n&stack=vertical&file=csv"


#상태 , 실패 클릭

#/html/body/div[1]/div/div[5]/div/div/div[2]/form/div/div[2]/div/button
remDr$findElement("xpath", '//*[@id="filter_and_search"]/div/div[2]/div/button')$clickElement()
Sys.sleep(5)
#/html/body/div[1]/div/div[5]/div/div/div[2]/form/div/div[2]/div/div/ul/li[5]/a
remDr$findElement("xpath", '//*[@id="filter_and_search"]/div/div[2]/div/div/ul/li[5]/a')$clickElement()
Sys.sleep(10)

#all 선택, 재추출 클릭
#/html/body/div[1]/div/div[5]/div/div/div[3]/div[2]/div[2]/table/thead/tr/th[1]/div[1]/input

remDr$findElement("xpath", '//*[@id="demo-custom-toolbar"]/thead/tr/th[1]/div[1]/input')$clickElement()
Sys.sleep(5)
remDr$findElement("xpath", '/html/body/div[1]/div/div[4]/div/div/button[2]')$clickElement()
Sys.sleep(2)
remDr$findElement("xpath", '/html/body/div[1]/div/div[4]/div/div/div[3]/div/div/div[3]/form/button')$clickElement()
Sys.sleep(2)

print(paste0("fail url re-extraction"))

remDr$close()
