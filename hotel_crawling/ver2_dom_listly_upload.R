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




# 구글 시트 불러오기
#Reads the data with Sheet ID into R
df <- read_sheet('1s7-lDV_jKnZfRjHVBFcSz-GmwRxiuw-wBN_t-V6ybWk') #, col_names = TRUE
#df <- read_sheet('1F4Wf4nXBNM1WqCaywAGcIYrcg6PW2EgWKJv1aAbl2e4') 

#링크가 없는 호텔 제외
df <- df[df$네이버메타링크 !=  "링크x", ]

# 숙소 이름 추출
df$hotel_name<- regmatches(df$네이버메타링크, regexpr("hotelFileName=hotel%3A[_a-zA-Z0-9]+&", df$네이버메타링크))
df$hotel_name <- gsub("hotelFileName=hotel%3A", "", df$hotel_name)
df$hotel_name <- gsub("&", "", df$hotel_name)



# createURL_v2
# 요청일자 1, 2 = 당일, 익일
base_url <- "https://hotels.naver.com/item/rates?hotelFileName=hotel%3A"
url_all <- NULL

for(j in 1:length(df$hotel_name)) {
  start <- Sys.Date() #+ 1 
  for(k in 1:2) {
    end <- start + 1
    url <- createURL_v2(base_url, df$hotel_name[j], start, end)
    # print(paste0("Current: start: ", start, " end: ", end, " City: ", city[j], " index: ", i))
    start <- start + 1
    url_all <- rbind(url_all, url)
  }
}

#요청일자 3 : 7일후. 강원은 14일후
for(j in 1:length(df$hotel_name)) {
  if (df$지역[j] !="강원") {
    start <- Sys.Date() + 7
  } else {
    start <- Sys.Date() + 14 
  }
  
  end <- start + 1
  url <- createURL_v2(base_url, df$hotel_name[j], start, end)
  # print(paste0("Current: start: ", start, " end: ", end, " City: ", city[j], " index: ", i))
  start <- start + 1
  url_all <- rbind(url_all, url)
}




######## listy로 크롤링


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

# Remove Old Urls
removeAllListly()
Sys.sleep(1)  

# listy 그룹 정보
gs4_deauth()
key <- "BDt5IaQMl0kpz92cFqtXf9aC0g2FTYNp" # "BDt5IaQMl0kpz92cFqtXf9aC0g2FTYNp" #listy token
url <- "https://www.listly.io/api/group?key=wulToaQn&arrange=y&href=n&stack=vertical&file=csv" 
#"https://www.listly.io/api/group?key=WNdnzQ7X&arrange=y&href=n&stack=vertical&file=csv"



# 임시로 3개 호텔만 가져오기
#url_all2 <- url_all
#url_all <- url_all2[1:60, ]
#url_all <- as.data.frame(url_all)
#nrow(url_all)  


max <- 30
iter <- ceiling(nrow(url_all)/max)
start <- 1
for(i in 1:iter) {
  Sys.sleep(3)
  end <- start + max
  if(end >= nrow(url_all)) {
    end <- nrow(url_all)
  }
  #openListly()
  url_sub <- url_all[start:end, ]
  url_sub <- as.data.frame(url_sub)
  colnames(url_sub) <- "url"
  url_list_string <- as.character(paste0(url_sub$url, collapse = "\n"))
  
  # Upload New Urls
  uploadListly(url_list_string)
  Sys.sleep(1)  
  print(paste0("Current: start: ", start, " end: ", end))
  start <- end + 1
  Sys.sleep(5)
  #remDr$close()
}

remDr$close()
#result_final_tb2<- result_final_tb


print(paste0("All URL uploaded to Listly at ", Sys.time()))


#result_final_tb



#rm(list = ls())

