--GPS相关的业务  若没有GPS卫星，则使用基站定位(5分钟更新一次基站)，并返回高德坐标系统  需要使用浮点数固件
--一分钟刷新一次坐标
module(..., package.seeall)
require "gpsv2"

local GaoDe_Location = {}

--返回高德地图坐标系
function Get_GaoDe_Location()
    return GaoDe_Location
end
function _transformlat(lng, lat)
    local pi = 3.1415926535897932384626 --π
    local ee = 0.00669342162296594323 --扁率
    ret = -100.0 + 2.0 * lng + 3.0 * lat + 0.2 * lat * lat + 0.1 * lng * lat + 0.2 * math.sqrt(math.abs(lng))
    ret = ret + (20.0 * math.sin(6.0 * lng * pi) + 20.0 * math.sin(2.0 * lng * pi)) * 2.0 / 3.0
    ret = ret + (20.0 * math.sin(lat * pi) + 40.0 * math.sin(lat / 3.0 * pi)) * 2.0 / 3.0
    ret = ret + (160.0 * math.sin(lat / 12.0 * pi) + 320 * math.sin(lat * pi / 30.0)) * 2.0 / 3.0
    return ret
end
function _transformlng(lng, lat)
    local pi = 3.1415926535897932384626 --π
    local ee = 0.00669342162296594323 --扁率
    ret = 300.0 + lng + 2.0 * lat + 0.1 * lng * lng + 0.1 * lng * lat + 0.1 * math.sqrt(math.abs(lng))
    ret = ret + (20.0 * math.sin(6.0 * lng * pi) + 20.0 * math.sin(2.0 * lng * pi)) * 2.0 / 3.0
    ret = ret + (20.0 * math.sin(lng * pi) + 40.0 * math.sin(lng / 3.0 * pi)) * 2.0 / 3.0
    ret = ret + (150.0 * math.sin(lng / 12.0 * pi) + 300.0 * math.sin(lng / 30.0 * pi)) * 2.0 / 3.0
    return ret
end
--返回真实的位置信息，坐标规范符合高德地图
function Run_Tran()
    
    local pi = 3.1415926535897932384626 --π
    local ee = 0.00669342162296594323 --扁率
    local a = 6378245.0 -- 长半轴
    --WGS84转GCJ02(火星坐标系)
    --lng:WGS84坐标系的经度
    --lat:WGS84坐标系的纬度
    local Location = {}
    if gpsv2.isFix() == true then
        Location.lng, Location.lat = gpsv2.getDegLocation()--获取经纬度
        log.error("Run_Tran", "GPS is Fix !")
    else
        Location.lng, Location.lat = gpsv2.getDeglbs()--获取经纬度
        log.error("Run_Tran", "Use LBS !")
    end
    Location.Altitude = gpsv2.getAltitude()--获取海拔
    local lng = Location.lng
    local lat = Location.lat
    
    dlat = _transformlat(lng - 105.0, lat - 35.0)
    dlng = _transformlng(lng - 105.0, lat - 35.0)
    radlat = lat / 180.0 * pi
    magic = math.sin(radlat)
    magic = 1 - ee * magic * magic
    sqrtmagic = math.sqrt(magic)
    dlat = (dlat * 180.0) / ((a * (1 - ee)) / (magic * sqrtmagic) * pi)
    dlng = (dlng * 180.0) / (a / sqrtmagic * math.cos(radlat) * pi)
    mglat = lat + dlat
    mglng = lng + dlng
    
    Location.lng = mglng
    Location.lat = mglat
    
    return Location
end
--GPS定位成功后的回调函数
local function GPS_OK(tag)
    while true do
        local Location = Run_Tran()
        GaoDe_Location = {}
        GaoDe_Location.Longitude = Location.lng
        GaoDe_Location.Latitude = Location.lat
        GaoDe_Location.Altitude = Location.Altitude
        GaoDe_Location.CoordinateSystem = 2 --告诉平台，使用的是高德坐标系
        log.error("GPS = ", GaoDe_Location.Longitude, GaoDe_Location.Latitude, GaoDe_Location.Altitude, GaoDe_Location.CoordinateSystem)
        sys.wait(60000)
    end
end
sys.taskInit(GPS_OK)
gpsv2.open(2, 115200, 2, 5)
