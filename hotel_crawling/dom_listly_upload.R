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
source("./manipulate/m_functions.R")

# group id 정보
listly_info <- fread("./listly/listly_info.csv")
listly_info <- as.data.frame(listly_info)

port_no <- 4480L  # 4480L Firefox

l_type <- "hotel_group"
curr_group <- listly_info %>% filter(listly_type == l_type) %>% 
  filter(group == 6)

# Create URLs
  # 네이버 호텔의 4개 도시: 서울, 제주, 부산, 강릉
  # Checkin: 내일 기준 앞으로 30일
base_url <- "https://hotels.naver.com/list?placeFileName=place%3A"
city <- c("Seoul", "Jeju_Province", "Busan_Province", "Gangneung")

url_all <- NULL
for(i in 0:1) {
  for(j in 1:length(city)) {
    start <- Sys.Date() + 1 
    for(k in 1:30) {
      end <- start + 1
      url <- createURL(base_url, city[j], start, end, i)
      # print(paste0("Current: start: ", start, " end: ", end, " City: ", city[j], " index: ", i))
      start <- start + 1
      url_all <- rbind(url_all, url)
    }
  }
}

url_all <- as.data.frame(url_all)
colnames(url_all) <- "url"
#url_all

# Listly Info
listly_type <- curr_group$listly_type
group_id <- "GBwAAfUN" # Hotel Group ID

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


max <- 30
iter <- ceiling(nrow(url_all)/max)
start <- 1
for(i in 1:iter) {
  end <- start + max
  if(end >= nrow(url_all)) {
    end <- nrow(url_all)
  }
  url_sub <- url_all[start:end, ]
  url_sub <- as.data.frame(url_sub)
  colnames(url_sub) <- "url"
  url_list_string <- as.character(paste0(url_sub$url, collapse = "\n"))
  # Upload New Urls
  uploadListly(url_list_string)
  Sys.sleep(1)  
  print(paste0("Current: start: ", start, " end: ", end))
  start <- end + 1
}

remDr$close()

print(paste0("All URL uploaded to Listly at ", Sys.time()))
