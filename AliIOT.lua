--链接阿里云物联网套件   通过MQTT方式和云交互

--平台需要新建的属性  HeartRate  RSSI  BatteryLevel GeoLocation.Longitude  GeoLocation.Latitude  GeoLocation.Altitude
--平台需要新建的事件  TUMBLE->MESSAGE  跌倒一次就立马上报一次告警事件

--硬件端每2分钟上报一次属性。告警事件来临立马上报。

module(...,package.seeall)

require"aLiYun"
require"misc"
require"pm"
require"Config"
require"nvm"
require "net"
require "mqtt"
require "pins"

--阿里云客户端是否处于连接状态
local sConnected

--库函数的要求，写的一个转换子函数
local function getDeviceName()
    return nvm.get("DeviceName")
end
--库函数的要求，写的一个转换子函数
local function getDeviceSecret()
    return nvm.get("DeviceSecret")
end
--上报各个属性
local function Pub_Property()
    if sConnected then  --只有链接成功才执行上报任务
        --属性上报主题
        GeoLocation = GetLocation.Get_GaoDe_Location()
        local Propety_TOPIC = "/sys/"..nvm.get("ProductKey").."/"..getDeviceName().."/thing/event/property/post"
        local PayLoad = {}
        PayLoad.id = 1
        PayLoad.version = "1.0"
        PayLoad.method = "thing.event.property.post"
        local Params = {}
        Params.HeartRate = MAX30100.Get_HeartRate()
        Params.RSSI = net.getRssi()
        Params.BatteryLevel = misc.getVbatt()
        if GeoLocation.Longitude>1 then --刚开机读取的坐标接近0，过滤掉
            Params.GeoLocation = GeoLocation
        end
        PayLoad.params = Params
        PayLoad = json.encode(PayLoad)
        aLiYun.publish(Propety_TOPIC,PayLoad)   --上报阿里云属性  
    end
end
--上报一个事件
local function Pub_TUMBLE()
    if sConnected then  --只有链接成功才执行上报任务
        --事件上报主题
        local Event_TOPIC = "/sys/"..nvm.get("ProductKey").."/"..getDeviceName().."/thing/event/TUMBLE/post"
        local PayLoad = {}
        PayLoad.id = 2
        PayLoad.version = "1.0"
        PayLoad.method = "thing.event.alarmEvent.post"
        local Params = {}
        Params.MESSAGE = "SOS"
        PayLoad.params = Params
        PayLoad = json.encode(PayLoad)
        aLiYun.publish(Event_TOPIC,PayLoad)  --上报事件
    end
end
--- 连接结果的处理函数
local function connectCbFnc(result)
    sConnected = result
    log.info("AliIOT.Fail_Count.result",result)
    if sConnected==true then
        Pub_Property()
    end
end
--开机初始化设备
function Init_Device()
    --配置阿里云的链接参数
    aLiYun.setMqtt(1,nil,60)
    aLiYun.setup(nvm.get("ProductKey"),nil,getDeviceName,getDeviceSecret)
    aLiYun.on("connect",connectCbFnc)
end

Init_Device() --初始化IOT参数
sys.timerLoopStart(Pub_Property,2*60*1000) --2分钟上报一次属性
sys.subscribe("SOS", Pub_TUMBLE) --订阅“SOS”，检测到摔倒立即发送SOS
require"aLiYunOta"
--如果利用阿里云OTA功能去下载升级合宙模块的新固件，默认的固件版本号格式为：_G.PROJECT.."_".._G.VERSION.."_"..sys.getcorever()，下载结束后，直接重启，则到此为止，


