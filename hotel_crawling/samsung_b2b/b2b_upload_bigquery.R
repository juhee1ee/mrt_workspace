#### 항공 프로모션 copy, TNA에 맞게 수정해야함
######################################
#          Listly Get Data           #
######################################


library(readr)
library(httr)
library(rvest)
library(openssl)
library(stringr)
library(RCurl)
library(DBI)
library(data.table)
library(dplyr)
library(googlesheets4)
library(lubridate)
library(bigrquery)
library(gargle)

##########################################
# Connect to bigquery

bigauth <- "/home/chulmin/mrtdata-647838e9df70.json"
# authenticate
bigrquery::bq_auth(path = bigauth)
# set my project ID and dataset name
project_id <- 'mrtdata'
dataset_name <- 'business'

bq_business <- dbConnect(
  bigrquery::bigquery(),
  project = "mrtdata",
  dataset = "business"
)



# listy 그룹 정보
gs4_deauth()
key <- "BDt5IaQMl0kpz92cFqtXf9aC0g2FTYNp" # "BDt5IaQMl0kpz92cFqtXf9aC0g2FTYNp" #listy token
url <- "https://www.listly.io/api/group?key=wulToaQn&arrange=y&href=n&stack=vertical&file=csv" 

# 데이터 가져오기
data_key <- GET(url, config = add_headers("Authorization" = key))
result <- content(data_key)
result_table <- fread(result)
result_table1 <- result_table[, c(2,15, 17)] #url, 객실이름, 최저가
print(paste0("fread result"))  




# 테이블 전처리
result_final_tb <- NULL
result_final_tb <- result_table1
colnames(result_final_tb) <- c("url","room_nm","min_price")


# 숙소 이름 추출
result_final_tb$naver_hotel_nm<- regmatches(result_final_tb$url, regexpr("hotelFileName=hotel%3A[_a-zA-Z0-9]+&", result_final_tb$url))
result_final_tb$naver_hotel_nm <- gsub("hotelFileName=hotel%3A", "", result_final_tb$naver_hotel_nm)
result_final_tb$naver_hotel_nm <- gsub("&", "", result_final_tb$naver_hotel_nm)

result_final_tb$checkin<- regmatches(result_final_tb$url, regexpr("checkIn[=][0-9]+[-][0-9]+[-][0-9]+", result_final_tb$url))
result_final_tb$checkin <- gsub("checkIn=", "", result_final_tb$checkin)
result_final_tb$checkout<- regmatches(result_final_tb$url, regexpr("checkOut[=][0-9]+[-][0-9]+[-][0-9]+", result_final_tb$url))
result_final_tb$checkout <- gsub("checkOut=", "", result_final_tb$checkout)

result_final_tb$min_price <- gsub(",", "", result_final_tb$min_price)

result_final_tb$basis_date <- Sys.Date()
result_final_tb$updated_at <- Sys.time()





### #구글시트에서 지역, 순위 정보가져와서 join
# 구글 시트 불러오기
#Reads the data with Sheet ID into R
df <- read_sheet('1gmLTGUbiBTFqdnA7eOilCeyUWACyHhE-KcAuZCedqxY') #, col_names = TRUE

# 숙소 이름 추출
df$hotel_name<- regmatches(df$URL, regexpr("hotelFileName=hotel%3A[_a-zA-Z0-9]+&", df$URL))
df$hotel_name <- gsub("hotelFileName=hotel%3A", "", df$hotel_name)
df$hotel_name <- gsub("&", "", df$hotel_name)

stat <- df[, c(1,3)] 
colnames(stat) <- c( "hotel_nm", "naver_hotel_nm")

result_final_tb <- merge(x=result_final_tb, y=stat, by='naver_hotel_nm')
result_final_tb <- result_final_tb[,-c("naver_hotel_nm")]


result_final_tb <- result_final_tb %>%
  select(basis_date, hotel_nm, room_nm, checkin, checkout, min_price, updated_at, url)



###################################
# Update to bigquery table

# Need to create table
table_nm <- 'samsung_b2b_hotel_price_crawling'



# Bigquery Table
keyword_ranking <- bq_table(project = project_id, dataset = dataset_name, table = table_nm)

colNms <- colnames(result_final_tb)
classNm <- c("date", "string", "string", "date","date", "numeric", "datetime",  "string")

# Create bigquery table fields
table_fields <- lapply(1:length(colNms), function(x) bq_field(colNms[x], classNm[x]))

# Update Missing data
uploaded <- bq_table_upload(x = keyword_ranking, values = result_final_tb,
                            fields = table_fields,
                            create_disposition='CREATE_IF_NEEDED', write_disposition='WRITE_APPEND')

# If failed then run again
if(uploaded$table == table_nm) {
  print(paste0("Table has been updated at ", Sys.time()))
} else {
  # Update Missing data
  uploaded <- bq_table_upload(x = schedule_detail, values = result,
                              fields = table_fields,
                              create_disposition='CREATE_IF_NEEDED', write_disposition='WRITE_APPEND')
}


