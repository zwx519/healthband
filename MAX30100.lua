--心率传感器 MAX30100
module(...,package.seeall)

require "sys"
require "misc"
require "pins"

local HeartRate=0 --计算好的心率
local HR_ADC={} --存放心率ADC数据的内存
local HR_ADC_Count=1 --心率ADC数据计数器
local HR_MAX_Count = 100 --心率ADC采样最大次数  每次采样间隔100ms，若100次则10S



--返回计算OK的心率数据
function Get_HeartRate()
    return HeartRate
end
--初始化MAX30100
function Init_MAX30100()
    local i2cslaveaddr = 0x57
    local i2cid = 2
    if i2c.setup(i2cid,i2c.SLOW) ~= i2c.SLOW then
        log.error("Init_MAX30100.iic","fail")
        return
    end
    i2c.send(i2cid,i2cslaveaddr,{0X06,0x40}) --复位心率
    rtos.sleep(100)
    i2c.send(i2cid,i2cslaveaddr,{0X06,0x0B}) --打开SPO2  ，  0X0A为HR Only 模式   
    i2c.send(i2cid,i2cslaveaddr,{0X01,0x20}) --打开 HR 硬件中断。
    i2c.send(i2cid,i2cslaveaddr,{0X09,0x11}) --两个LED电流设置为 4.4ma
    -- i2c.send(i2cid,i2cslaveaddr,{0X07,0x43}) --使能SPO2高分辨率模式
    -- i2c.send(i2cid,i2cslaveaddr,{0X02,0x00}) --FIFO-WR-PTR
    -- i2c.send(i2cid,i2cslaveaddr,{0X03,0x00}) --OVF_COUNTER
    -- i2c.send(i2cid,i2cslaveaddr,{0X04,0xFF}) --FIFO_RD_PTR
    i2c.close(i2cid)
end
--读取心率ADC数据
function Read_MAX30100()
    local i2cslaveaddr = 0x57
    local i2cid = 2
    if i2c.setup(i2cid,i2c.SLOW) ~= i2c.SLOW then
        log.error("Init_MAX30100.iic","fail")
        return
    end

    local Data = 0
    i2c.send(i2cid,i2cslaveaddr,0x00)
    Data = i2c.recv(i2cid,i2cslaveaddr,1)
    --log.info("Read_MAX30100.1",Data:toHex())

    --若HR中断有效，则读取数据
    if Data:byte()==0x20 then
        i2c.send(i2cid,i2cslaveaddr,0x05)
        Data = i2c.recv(i2cid,i2cslaveaddr,4)
        Data = Data:byte(1)*256+Data:byte(2)
        table.insert(HR_ADC,Data) --插入HR数据到数组
        HR_ADC_Count = HR_ADC_Count + 1
        --log.info("Read_MAX30100.2",Data:toHex())
        --log.info("Read_MAX30100.3",Data:byte(1),Data:byte(2))
        --log.info("Read_MAX30100.4",Data)
    end
    i2c.close(i2cid)

    if HR_ADC_Count > HR_MAX_Count then
        local Max = 0 --数组中大于平均数的数据
        for i=1,HR_MAX_Count-1 do
            --log.info("Read_MAX30100.5",HR_ADC[i])
            if (HR_ADC[i]-HR_ADC[i+1])>40 then 
                Max = Max + 1
            end
        end
        HeartRate = Max * 6 / 2 --次/分钟
        log.error("Read_MAX30100.6",HeartRate)
        --清空HR_ADC数组
        HR_ADC_Count = 1
        HR_ADC={}
    end
end

Init_MAX30100() --初始化心率
sys.timerLoopStart(Read_MAX30100,100) --每秒采样10次




