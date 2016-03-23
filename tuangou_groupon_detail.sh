# !/bin/sh 

DATE=`date +%Y%m%d -d "${1:-1 day ago}"` #输入日期
DT=`date +%m%d -d "${1:-1 day ago}"` #输入日期
DATES=`date +%m/%d -d "${1:-1 day ago}"`
DATE_30T=`date +%m/%d -d "${DATES} -29 day"`
DATE_25T=`date +%m/%d -d "${DATES} -24 day"`

MAIL_HTML=/home/zhangwei/html/tuangou_groupon_detail.html

##read mysql data to shell global variable;
#***********************************#
#本周收益
read profit_this_app profit_this_wx profit_this_all profit_this_all_app profit_this_all_wx<<< `mysql -h127.0.0.1 -uroot -pddxq@100.me -N -e"set names utf8;
select round(sum(if(user_type=1, pay_money, 0))/sum(pay_money)*100,2) app_money, round(sum(if(user_type=2, pay_money,0))/sum(pay_money)*100,2) wx_money, sum(pay_money),sum(if(user_type=1, pay_money, 0)),sum(if(user_type=2, pay_money, 0)) 
from ddxq_tuangou.order 
where pay_status=2
and date(from_unixtime(pay_time))>=date_add(date(now()),interval -7 day);"`
#上周收益
read profit_last_all_app profit_last_all_wx<<< `mysql -h127.0.0.1 -uroot -pddxq@100.me -N -e"set names utf8;
select group_concat(app_money), group_concat(wx_money)
from 
(select ceil(datediff(date(now()),date(from_unixtime(pay_time)))/7) cz,sum(pay_money), sum(if(user_type=1, pay_money, 0)) app_money,sum(if(user_type=2, pay_money, 0)) wx_money 
from ddxq_tuangou.order 
where pay_status=2
and date(from_unixtime(pay_time))>=date_add(date(now()),interval -35 day)
and date(from_unixtime(pay_time))<=${DATE}
group by 1
order by 1 desc) tmp;"`
#活跃用户量
read active_user<<< `mysql -h127.0.0.1 -uroot -pddxq@100.me -N -e"set names utf8;
select format(count(distinct uid),0) group_user 
from ddxq_user_state.ddxq_delivery_buried_point 
where appkey='6292cec41944528014c40d60' 
and date(data_desc)>=date_add(date(now()),interval -1 day) 
and uid not like 'a%';"`
#团购中
read grouponing<<< `mysql -h127.0.0.1 -uroot -pddxq@100.me -N -e"set names utf8;
select count(distinct id)
from ddxq_tuangou.groupon
where status=5;"`
#累计金额及累计用户量
read all_money all_user <<< `mysql -h127.0.0.1 -uroot -pddxq@100.me -N -e"set names utf8;
select format(sum(pay_money),2), format(count(distinct user_id),0)
from ddxq_tuangou.order
where pay_status=2;"`
#累计开团团主数
read organizer <<< `mysql -h127.0.0.1 -uroot -pddxq@100.me -N -e"set names utf8;
select count(distinct organizer_id)
from ddxq_tuangou.groupon
where status in ('4','5','7','9','11');"`
#下单用户及金额趋势
read dt order_users pay_money <<< `mysql -h127.0.0.1 -uroot -pddxq@100.me -N -e"set names utf8;
select group_concat(concat(\"'\",dt,\"'\")), group_concat(users), group_concat(pay_money)
from(select date(from_unixtime(pay_time)) dt, count(distinct user_id) users, sum(pay_money) pay_money
from ddxq_tuangou.order 
where pay_status=2
and date(from_unixtime(pay_time))<=${DATE}
group by 1) tmp;"`



#send mail
#注意修改头文件中的按钮触发事件
(
cat /home/zhangwei/html/report_body.html
echo "<meta http-equiv=\"content-type\" content=\"text/html; charset=utf-8\"/>
</head>
<body onload=\"loadFun()\">"
)>${MAIL_HTML}

#js统计图像函数
#**************#
#饼图直方图
(
echo "<script type=\"text/javascript\" src=\"/js/jquery-1.11.0.min.js\"></script>
  <script type=\"text/javascript\" src=\"/js/highcharts/highcharts.js\"></script>
  <script>
    \$(function () {
      \$('#profitchannel').highcharts({
        chart: {
            plotBackgroundColor: null,
            plotBorderWidth: null,
            plotShadow: false
        },
        title: {
            text: '邻里团一周收益渠道分布图',
            style: {
                color: 'black',
                fontWeight: 'bold',
                fontSize: '25px'
            }
        },
        tooltip: {
            pointFormat: '{series.name}: <b>{point.percentage:.1f}%</b>'
        },
        plotOptions: {
            pie: {
                allowPointSelect: true,
                cursor: 'pointer',
                dataLabels: {
                    enabled: true,
                    format: '<b>{point.name}</b>: {point.percentage:.1f} %',
                    style: {
                        color: (Highcharts.theme && Highcharts.theme.contrastTextColor) || 'black'
                    }
                }
            }
        },
        series: [{
            type: 'pie',
            name: '流水占比',
            data: [
                {name: 'APP',   
                 y: ${profit_this_app},
                 color: '#ab2e83'},
                {
                    name: 'Wechat',
                    y: ${profit_this_wx},
                    color:'#0057e7',
                    sliced: true,
                    selected: true
                }
            ]
        }]
    });
    \$('#profitweek').highcharts({

        chart: {
            type: 'column'
        },

        title: {
            text: '周流水对比',
            style: {
                color: 'black',
                fontWeight: 'bold',
                fontSize: '25px'
            }
        },

        xAxis: {
            categories: ['近5周', '近4周','近3周', '近2周','近1周']
        },

        yAxis: {
            allowDecimals: false,
            min: 0,
        },

        tooltip: {
            formatter: function () {
                return '<b>' + this.x + '</b><br/>' +
                    this.series.name + ': ' + this.y + '<br/>' +
                    'Total: ' + this.point.stackTotal;
            }
        },

        plotOptions: {
            column: {
                stacking: 'normal'
            }
        },

        series: [{
            name: 'APP',
            data: [${profit_last_all_app}],
            color:'#ab2e83'
        }, {
            name: 'Wechat',
            data: [${profit_last_all_wx}],
            color: '#0057e7'
        }]
    });
    \$('#profitusers').highcharts({
        chart: {
            zoomType: 'xy'
        },
        title: {
            text: '邻里团流水及用户量走势',
            style: {
                color: 'black',
                fontWeight: 'bold',
                fontSize: '25px'
            }
        },
        xAxis: [{
            categories: [${dt}],
            crosshair: true,
            tickInterval: 10
        }],
        yAxis: [{ // Primary yAxis
            labels: {
                format: '{value}',
                style: {
                    color: Highcharts.getOptions().colors[1]
                }
            },
            title: {
                text: '金额',
                style: {
                    color: Highcharts.getOptions().colors[1]
                }
            }
        }, { // Secondary yAxis
            title: {
                text: '参团人数',
                style: {
                    color: Highcharts.getOptions().colors[0]
                }
            },
            labels: {
                format: '{value}',
                style: {
                    color: Highcharts.getOptions().colors[0]
                }
            },
            opposite: true
        }],
        tooltip: {
            shared: true
        },
        legend: {
            layout: 'vertical',
            align: 'left',
            x: 120,
            verticalAlign: 'top',
            y: 100,
            floating: true,
            backgroundColor: (Highcharts.theme && Highcharts.theme.legendBackgroundColor) || '#FFFFFF'
        },
        series: [{
            name: '参团用户',
            type: 'column',
            yAxis: 1,
            color:'#0057e7',
            data: [${order_users}],
            tooltip: {
                valueSuffix: '人'
            }

        }, {
            name: '交易流水',
            type: 'spline',
            color: '#d62d20',
            data: [${pay_money}],
            tooltip: {
                valueSuffix: '元'
            }
        }]
    });
});
  </script>"
) >>${MAIL_HTML}

#页面分区内容(容器)
##导航栏
(
  cat /home/zhangwei/html/report_menu.html
##正文内容
echo "<div id=\"content\">
<table align=\"center\" border=\"0\">
  <tr>
    <td colspan=\"2\">
     <table align=\"center\" border=\"0\">
      <tr>
        <td align=\"left\"><span id=\"profitchannel\" style=\"width: auto; height: auto; margin: 0 auto;clear:both\"></span></td>
        <td valign=\"top\"> 
            <table border=\"0\">
              <tr><td height=\"60px\"><font size=\"5\" face=\"Impact\">${DATES}关键指标</font></td></tr>
              <tr><td><font size=\"4\" face=\"Impact\">累计金额：</font></td><td bgcolor=\"ff00ff\"><font size=\"6\" face=\"consolas\" color="#ffffff">￥${all_money}</font></td></tr>
              <tr><td><font size=\"4\" face=\"Impact\">累计用户：</font></td><td><font size=\"5\" face=\"consolas\" color="#ab2e83">${all_user}人</font></td></tr>
              <tr><td><font size=\"4\" face=\"Impact\">累计开团团主：</font></td><td><font size=\"5\" face=\"consolas\" color="#ab2e83">${organizer}人</font></td></tr>
              <tr><td><font size=\"4\" face=\"Impact\">团活跃：</font></td><td><font size=\"5\" face=\"consolas\" color="#ab2e83">${active_user}人</font></td></tr>
              <tr><td><font size=\"4\" face=\"Impact\">团购中：</font></td><td><font size=\"5\" face=\"consolas\" color="#ab2e83">${grouponing}个</font></td></tr>
            </table>
        </td>
      </tr>
     </table>
    </td>
  </tr>
  <tr>
    <td colspan=\"2\" align=\"center\" ><span id=\"profitusers\" style=\"min-width: 1000px;max-width:100% ; height: auto; margin: 0 auto;clear:both\"></span>
    </td>
  </tr>
  <tr>
    <td rowspan=\"2\" align=\"left\"><span id=\"profitweek\" style=\"width: auto; height: auto; margin: 0 auto;clear:both\"></span>
    </td>
    <td align=\"center\" >
      <font size=\"5\" face=\"consolas\" color="#aaaaaa">指标说明</font>
    </td>
  </tr>
  <tr>
    <td><font size=\"4\" face=\"consolas\" color="#aaaaaa">
       <ul>
          <li>左上饼图表示渠道收益的占比；右上关键指标中“团活跃”是指剔除游客后的访问邻里团购的用户量，累计量均指从邻里团上线开始统计；</li>
          <li>上图的趋势图中的参团用户数指每天下单并支付的用户数，交易流水指每天下单并支付完成的金额；</li>
          <li>左下表描述截止目前最近一周内正在团购中的交易收益；相应地，右下表描述截止目前最近一周内已经结束的团购的交易收益；</li>
       </ul></font>
    </td>
  </tr>
" 
echo "<tr bgcolor=\"#eeeeee\"><td align=\"center\" valign=\"top\">
        <font size=\"5\" face=\"consolas\">团主近一周收益（团购中）</font>
        <font size=\"4\" face=\"consolas\">"
mysql -h127.0.0.1 -uroot -p"ddxq@100.me"  -H -e "set names utf8;
select a.organizer_id \`团主ID\`,
       c.nick_name \`团主昵称\`, 
       count(distinct b.user_id) \`参团用户\`, 
       count(distinct if(user_type=1,b.user_id,null)) \`APP用户\`, 
       count(distinct if(user_type=2,b.user_id,null)) \`微信用户\`, 
       format(sum(if(b.pay_money is null,0,b.pay_money)),2) \`交易流水\`
from ddxq_tuangou.groupon a
left join ddxq_tuangou.order b on b.groupon_id=a.id and b.pay_status=2 and date(from_unixtime(b.pay_time))>=date_add(date(now()),interval -7 day)
left join ddxq_tuangou.organizer c on a.organizer_id=c.id
where a.status=5
group by 1
order by sum(if(b.pay_money is null,0,b.pay_money)) desc;"
echo "</font></td>
<td align=\"center\" valign=\"top\">
        <font size=\"5\" face=\"consolas\">团主近一周收益（已结束）</font>
        <font size=\"4\" face=\"consolas\">"
mysql -h127.0.0.1 -uroot -p"ddxq@100.me"  -H -e "set names utf8;
select a.organizer_id \`团主ID\`,
       c.nick_name \`团主昵称\`, 
       count(distinct b.user_id) \`参团用户\`, 
       count(distinct if(user_type=1,b.user_id,null)) \`APP用户\`, 
       count(distinct if(user_type=2,b.user_id,null)) \`微信用户\`, 
       format(sum(if(b.pay_money is null,0,b.pay_money)),2) \`交易流水\`
from ddxq_tuangou.groupon a
left join ddxq_tuangou.order b on b.groupon_id=a.id and b.pay_status=2 and date(from_unixtime(b.pay_time))>=date_add(date(now()),interval -7 day)
left join ddxq_tuangou.organizer c on a.organizer_id=c.id
where a.status=7
group by 1
order by sum(if(b.pay_money is null,0,b.pay_money)) desc;"
echo "</font></td>
  </tr>
</table>
</div>"
echo "<div id=\"footer\">Copyright 数据部 | 更多数据请访问<a href=\"http://stat.ddxq.mobi/\">统计后台</a></div>"
echo "</div>"
echo "</body></html>"	
	)>> ${MAIL_HTML}
rsync -razP --port=8730 /home/zhangwei/html/tuangou_groupon_detail.html 10.8.64.41::www/

