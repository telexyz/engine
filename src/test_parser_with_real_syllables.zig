const std = @import("std");

const parsers = @import("./syllable_parsers.zig");

fn print(comptime fmt_str: []const u8, args: anytype) void {
    if (false)
        // if (true)
        std.debug.print(fmt_str, args);
}

inline fn canBeVi(word: []const u8) bool {
    // print("\n\nword: '{s}'\n", .{ word });
    return parsers.parseAmTietToGetSyllable(true, print, word).can_be_vietnamese;
}

const expect = @import("std").testing.expect;

test "vn syllables special cases" {
    const words: []const []const u8 = &.{ "uở", "hươ", "huơ", "khuơ", "HUƠ", "KHUƠ" }; // hua, khua
    for (words) |word| try expect(canBeVi(word));

    // try expect(canBeVi("têt")); ??
    // try expect(canBeVi("xit")); ??
    // try expect(canBeVi("gip")); ??
    // try expect(canBeVi("gram")); // mượn từ tiếng Anh
    // try expect(canBeVi("gỵa")); // gịa?
    // https://www.rongmotamhon.net/static/chimviet/quehuong/nguyendu/nddg102.htm
    // Từ đơn gịa không có trong từ điển của Hoàng Phê. Đại Nam quốc âm tự vị của Huỳnh Tịnh Của (1895) định nghĩa gịa là đồ đong lúa, tức là từ giạ của Hoàng Phê.
}

test "all(-most) vn syllables in UPPERCASE" {
    const words_str = "a ai am an ang anh ao au ba bai ban bang banh bao bay be bem ben beng beo bi bia bin binh biên biêng biếc biếm biến biếng biết biếu biền biển biểu biện biệt bo bom bon bong boong boóng bu bua bung buôn buông buýt buốt buồi buồm buồn buồng buổi buộc buột bà bài bàm bàn bàng bành bào bàu bày bá bác bách bái bám bán báng bánh báo bát báu bân bâng bâu bây bã bãi bão bè bèm bèn bèo bé béc bén béng béo bép bét bê bên bênh bêu bì bìa bìm bình bìu bí bích bím bính bít bíu bò bòi bòm bòn bòng bó bóc bói bón bóng bóp bót bô bôi bôm bôn bông bõ bõm bõng bù bùa bùi bùm bùn bùng bú búa búi bún búng búp bút băm băn băng bĩ bĩnh bĩu bũm bơ bơi bơm bơn bư bưa bưng bưu bươi bươm bươn bương bươu bước bướm bướng bướp bướu bưởi bượt bạ bạc bạch bại bạn bạnh bạo bạp bạt bạu bả bải bản bảng bảnh bảo bảu bảy bấc bấm bấn bấp bất bấu bấy bầm bần bầng bầu bầy bẩm bẩn bẩy bẫm bẫy bậc bậm bận bập bật bậu bậy bắc bắn bắng bắp bắt bằm bằn bằng bẳn bẵng bặm bặn bặng bặp bặt bẹ bẹn bẹo bẹp bẹt bẻ bẻm bẻo bẽ bẽn bẽo bế bến bếp bết bề bền bềnh bều bể bễ bệ bệch bện bệnh bệt bệu bỉ bỉm bỉnh bỉu bị bịa bịch bịn bịnh bịp bịt bịu bọ bọc bọn bọng bọp bọt bỏ bỏi bỏm bỏng bố bốc bối bốn bống bốp bốt bồ bồi bồm bồn bồng bổ bổi bổn bổng bỗ bỗng bộ bộc bội bộn bộng bộp bột bớ bới bớp bớt bờ bời bờm bờn bở bởi bỡ bỡn bợ bợm bợn bợp bợt bụ bụa bục bụi bụm bụng bụp bụt bủ bủa bủm bủn bủng bứ bức bứng bứt bừa bừng bửa bửng bửu bữa bự bựa bực bựt ca cai cam can canh cao cau cay cha chai chan chang chanh chao chau chay che chem chen cheng cheo chi chia chim chinh chiu chiêm chiên chiêng chiêu chiếc chiếm chiến chiếng chiếp chiết chiếu chiền chiềng chiều chiểu chiện cho choang choi chong choài choàng choá choái choán choáng choãi choèn choé choòng choăn choạc choạng choạp choảng choắt choẹ choẹt chu chua chui chum chun chung chuyên chuyến chuyền chuyển chuyện chuôi chuôm chuông chuẩn chuếch chuệch chuốc chuối chuốt chuồi chuồn chuồng chuỗi chuộc chuội chuộng chuột chuỳ chà chài chàm chàng chành chào chày chá chác chái chán cháng chánh cháo chát cháu cháy châm chân châu chây chã chãi chão chè chèn chèo ché chém chén chéo chép chét chê chêm chênh chì chìa chìm chình chìu chí chích chím chín chính chíp chít chíu chò chòi chòm chòng chó chóc chói chóng chóp chót chôm chôn chông chõ chõm chõng chù chùa chùi chùm chùn chùng chú chúa chúc chúi chúm chúng chút chăm chăn chăng chĩa chĩn chĩnh chũi chũm chũn chơ chơi chơm chơn chư chưa chưn chưng chương chước chướng chườm chường chưởi chưởng chưỡng chược chượp chạ chạc chạch chạm chạn chạng chạnh chạo chạp chạt chạy chả chải chảnh chảo chảu chảy chấm chấn chấp chất chấu chấy chầm chần chầu chầy chẩm chẩn chẫu chậc chậm chận chập chật chậu chắc chắm chắn chắp chắt chằm chằn chằng chẳng chẵn chặc chặm chặn chặng chặp chặt chẹn chẹo chẹp chẹt chẻ chẻm chẻn chẻo chẽ chẽn chế chếch chếnh chết chề chềm chềnh chểnh chễm chễnh chệ chệch chện chệnh chỉ chỉn chỉnh chị chịa chịt chịu chọ chọc chọi chọn chọt chỏ chỏm chỏn chỏng chốc chối chốn chống chốp chốt chồ chồi chồm chồn chồng chổi chổng chỗ chỗm chộ chội chộn chộp chột chớ chới chớm chớp chớt chờ chờm chờn chở chởm chợ chợn chợp chợt chục chụm chụp chụt chủ chủn chủng chứ chứa chức chứng chừ chừa chừng chửa chửi chửng chữ chữa chững chực co coi com con cong coong coóc cu cua cui cum cun cung cuốc cuối cuốn cuống cuồn cuồng cuỗm cuộc cuội cuộn cuộng cà cài càn càng cành cào càu cày cá các cách cái cám cán cáng cánh cáo cáp cát cáu cáy câm cân câng câu cây cãi cò còi còm còn còng có cóc cói cóng cóp cót cô côi côm côn công cõi cõng cù cùi cùm cùn cùng cú cúa cúc cúi cúm cúng cúp cút căm căn căng cũ cũi cũn cũng cơ cơi cơm cơn cư cưa cưng cưu cương cước cưới cướp cười cườm cường cưỡi cưỡng cạ cạc cạch cạm cạn cạnh cạo cạp cạu cạy cả cải cảm cản cảng cảnh cảo cảu cảy cấc cấm cấn cấp cất cấu cấy cầm cần cầu cầy cẩm cẩn cẩu cẩy cẫm cẫn cẫng cận cập cật cậu cậy cắc cắm cắn cắp cắt cằm cằn cẳn cẳng cẵng cặc cặm cặn cặp cặt cọ cọc cọm cọn cọng cọp cọt cỏ cỏi cỏm cỏn cỏng cố cốc cối cốm cốn cống cốp cốt cồ cồm cồn cồng cổ cổi cổn cổng cỗ cỗi cộ cộc cội cộm cộn cộng cộp cột cớ cớm cớn cớt cờ cời cờn cởi cỡ cỡi cỡm cỡn cợn cợt cụ cục cụi cụm cụng cụp cụt củ của củi củn củng cứ cứa cức cứng cứt cứu cừ cừu cử cửa cửi cửng cửu cữ cữu cự cựa cực cựu da dai dam dan dang danh dao day de deo di dim dinh diêm diên diêu diếc diếp diết diếu diềm diều diễm diễn diễu diệc diện diệp diệt diệu do doa doan doanh doi dom don dong doành doá doãi doãn doãng doạ du dua dun dung duy duyên duyệt duềnh duệ duốc duỗi dà dài dàn dàng dành dào dàu dày dá dác dái dám dán dáng dát dáy dâm dân dâng dâu dây dã dãi dãy dè dèn dé dép dê dênh dì dìa dìm dìu dí dích dím dính díp díu dò dòi dòm dòng dó dóc dóm dón dót dô dôi dông dõi dõng dù dùa dùi dùn dùng dúa dúi dúm dún dúng dút dăm dăn dăng dĩ dĩa dĩnh dũ dũi dũng dơ dơi dư dưa dưng dương dưới dướng dường dưỡng dược dượng dượt dạ dạc dại dạm dạn dạng dạo dạt dạy dả dải dảy dấm dấn dấp dấu dấy dầm dần dầu dẩn dẫm dẫn dẫu dẫy dậm dận dập dật dậu dậy dắng dắt dằm dằn dằng dẳng dặc dặm dặn dặng dặt dẹp dẹt dẻ dẻo dẽ dế dề dềnh dể dễ dện dệt dị dịch dịp dịt dịu dọc dọi dọn dọng dọp dỏ dỏm dỏng dốc dối dốt dồi dồn dỗ dỗi dội dộng dột dớ dớp dờ dời dở dởm dỡ dợ dụ dục dụm dụng dứ dứa dức dứt dừ dừa dừng dử dửng dữ dự dựa dực dựng e em en eng eo ga gai gam gan gang ganh gao gau gay ghe ghen ghi ghim ghiếc ghiền ghè ghèn ghé ghém ghép ghét ghê ghì ghìm ghẹ ghẹn ghẹo ghẻ ghẽ ghế ghếch ghề ghềnh ghểnh ghệt gi gia giai giam gian giang gianh giao gieo gio gioi gion giong giu giua giun giuộc già giàn giàng giành giào giàu giày giá giác giám gián giáng giáo giáp giát giâm giâu giây giã giãi giãn giãy gièm gié giéo giê giêng giò giòi giòn gió gióc giói gión gióng giô giôn giông giùi giùm giú giúi giúp giăm giăng giũ giũa giơ giương giướng giường giượng giạ giại giạng giạt giả giải giảm giản giảng giảnh giảo giảu giấc giấm giấp giấu giấy giầm giần giầu giầy giẫm giẫy giậm giận giập giật giậu giắn giắt giằm giằn giằng giặc giặm giặn giặt giẹo giẹp giẻ giếc giếm giếng giết giề giền giềng giễu giọ giọc giọi giọng giọt giỏ giỏi giỏn giỏng giối giống giốt giồ giồi giồng giổi giỗ giộ giội giộp giới giờ giời giờn giở giỡn giụa giục giụi giủi giừ giữ giữa giựt go gom gon goá goòng gu guốc guồi guồng guộc gà gài gàn gàng gành gào gàu gá gác gái gán gánh gáo gáp gáu gáy gâm gân gâu gây gã gãi gãy gì gìm gìn gí gích gíp gò gòn góc gói góp gót gô gôm gôn gông gõ gù gùi gùn gùng gút găm găn găng gũi gơ gươm gương gườm gường gưỡng gượm gượng gạ gạc gạch gạn gạnh gạo gạt gả gảy gấc gấm gấp gấu gấy gầm gần gầu gầy gẩm gẫm gẫu gậm gập gật gậy gắm gắn gắng gắp gắt gằm gằn gặc gặm gặn gặng gặp gặt gỉ gọi gọn gọng gọt gỏi gỏng gốc gối gốm gồ gồi gồm gồng gổ gỗ gộ gộc gội gộp gột gớm gờ gờm gờn gở gởi gỡ gợi gợn gợt gụ gục gụi gụt gừ gừng gửi ha hai ham han hang hanh hao hau hay he hem hen heo hi hia him hiu hiên hiêng hiếm hiến hiếng hiếp hiếu hiềm hiền hiểm hiển hiểu hiện hiệp hiệu ho hoa hoan hoang hoay hoe hoen hoi hom hon hong hoà hoài hoàn hoàng hoành hoá hoác hoán hoáy hoãn hoè hoét hoăm hoăng hoạ hoạch hoại hoạn hoạnh hoạt hoả hoải hoảng hoảnh hoắc hoắm hoắt hoẳn hoẵng hoặc hoẹ hoẹt hoẻn hu hua hum hun hung huy huynh huyên huyết huyền huyễn huyện huyệt huân huê huênh huý huých huýt huấn huếch huề huệ huống huỳnh huỵch huỷ hy hà hài hàm hàn hàng hành hào hàu há hác hách hái hám hán háng hánh háo hát háu háy hâm hân hâu hây hãi hãm hãn hãng hãnh hão hãy hè hèm hèn hèo hé héc héo hét hê hên hênh hì hình hí hích híp hít hò hòi hòm hòn hòng hóc hói hóm hóng hóp hót hô hôi hôm hôn hông hõm hù hùa hùm hùn hùng hú húc húi húng húp hút hăm hăng hĩm hĩnh hũ hũm hơ hơi hơn hư hưng hưu hương hươu hước hướm hướng hường hưởng hượm hạ hạc hạch hại hạm hạn hạng hạnh hạo hạp hạt hả hải hảm hảng hảo hấn hấng hấp hất hấu hấy hầm hầu hầy hẩm hẩng hẩu hẩy hẫng hẫu hậm hận hập hậu hắc hắn hắng hắt hằm hằn hằng hẳn hẵng hặc hẹ hẹm hẹn hẹp hẻm hẻo hếch hến hết hếu hề hềnh hể hển hểnh hệ hệch hệt hỉ hỉnh hịch họ học họng họp hỏi hỏm hỏn hỏng hố hốc hối hống hốt hồ hồi hồn hồng hổ hổi hổm hổn hổng hỗ hỗn hỗng hộ hộc hội hộn hộp hột hớ hớm hớn hớp hớt hờ hời hờn hở hởi hỡi hợi hợm hợp hợt hục hụi hụm hụp hụt hủ hủi hủn hứa hức hứng hừ hừm hừng hử hửng hữ hững hữu hự hực hựu i im in inh iu ke kem ken keng keo kha khai kham khan khang khanh khao khau khay khe khem khen kheo khi khin khinh khiu khiêm khiên khiêng khiêu khiếm khiến khiếp khiết khiếu khiền khiển khiễng kho khoa khoai khoan khoang khoanh khoe khoeo khom khoào khoá khoác khoái khoán khoáng khoát khoáy khoèo khoé khoét khoăm khoăn khoả khoải khoản khoảng khoảnh khoắm khoắn khoắng khoắt khoằm khoẻ khu khua khui khum khung khuy khuya khuynh khuyên khuyến khuyết khuyển khuân khuâng khuây khuê khuôn khuông khuất khuấy khuẩn khuếch khuỳnh khuỵu khuỷu khà khàn khàng khá khác khách khái khám khán kháng khánh kháo kháp khát kháu kháy khâm khân khâu khè khèn khèo khé khén khéo khép khét khê khênh khêu khì khìn khí khía khích khít khíu khò khòm khòng khó khóc khói khóm khô khôi khôn không khù khùng khú khúc khúm khăm khăn khăng khĩnh khơ khơi khư khươi khươm khươn khương khước khướt khướu khạc khạng khạo khả khải khảm khản khảng khảnh khảo khảy khấc khấm khấn khấp khất khấu khẩn khẩu khẩy khập khật khắc khắm khắng khắp khắt khằng khẳm khẳn khẳng khặc khẹc khẻ khẻo khẽ khế khề khều khểnh khệ khệnh khỉ khỉnh khịa khịt khọm khỏi khỏng khố khốc khối khốn khống khổ khổn khổng khớ khớp khờ khởi khụ khục khụt khủ khủng khứ khứa khứng khứu khừ khừng khử khựng ki kia kim kinh kiêm kiên kiêng kiêu kiếm kiến kiếp kiết kiếu kiềm kiền kiềng kiều kiểm kiểng kiểu kiễng kiệm kiện kiệt kiệu kè kèm kèn kèo ké kéc kém kén kéo kép két kê kênh kêu kì kìa kìm kình kí kích kín kính kíp kít ký kĩ kẹ kẹn kẹo kẹp kẹt kẻ kẻng kẻo kẽ kẽm kẽo kế kếch kếp kết kề kềm kền kềnh kều kể kệ kệch kệnh kỉ kỉnh kị kịch kịp kịt kỳ kỵ kỷ kỹ la lai lam lan lang lanh lao lau lay le lem len leng leo li lia lim lin linh liu liêm liên liêng liêu liếc liếm liến liếng liếp liềm liền liều liểng liễm liễn liễu liệm liệng liệp liệt liệu lo loa loan loang loanh loay loe loen loi lom lon long loong loà loài loàn loàng loáng loát loãng loè loé loét loăng loạc loại loạn loạng loạt loảng loắt loằng loẹt lu lua lui lum lung luya luyến luyện luân luôm luôn luông luýnh luấn luẩn luận luật luốc luống luốt luồn luồng luỗng luộc luộm luỵ luỹ ly là lài làm làn làng lành lào làu lá lác lách lái lán láng lánh láo láp lát láu láy lâm lân lâng lâu lây lã lãi lãm lãn lãng lãnh lão lè lèm lèn lèo lé léc lém lén léng léo lép lét lê lên lênh lêu lì lìa lìm lình lìu lí lính líp lít líu lò lòi lòm lòn lòng ló lóc lói lóm lóng lóp lót lô lôi lôm lông lõ lõi lõm lõng lù lùa lùi lùm lùn lùng lú lúa lúc lúi lúm lún lúng lúp lút lý lăm lăn lăng lĩnh lũ lũi lũm lũn lũng lơ lơi lơn lư lưng lưu lươm lươn lương lưới lướng lướt lười lườm lườn lường lưỡi lưỡng lược lượm lượn lượng lượt lạ lạc lạch lại lạm lạn lạng lạnh lạo lạp lạt lạu lạy lả lải lảm lảng lảnh lảo lảu lảy lấc lấm lấn lấp lất lấy lầm lần lầu lầy lẩm lẩn lẩu lẩy lẫm lẫn lẫy lận lập lật lậu lắc lắm lắng lắp lắt lằm lằn lằng lẳm lẳn lẳng lẵng lặc lặm lặn lặng lặp lặt lẹ lẹm lẹn lẹo lẹp lẹt lẻ lẻm lẻn lẻng lẻo lẽ lẽn lẽo lếch lết lếu lề lềnh lều lể lểu lễ lễu lệ lệch lệnh lỉm lỉnh lị lịa lịch lịm lịnh lịu lọ lọc lọi lọm lọn lọng lọt lỏi lỏm lỏn lỏng lố lốc lối lốm lốn lốp lốt lồ lồi lồm lồn lồng lổ lổm lổn lổng lỗ lỗi lộ lộc lội lộm lộn lộng lộp lột lớ lới lớn lớp lớt lờ lời lờm lờn lở lởi lởm lởn lỡ lỡm lợ lợi lợm lợn lợp lợt lụ lụa lục lụi lụn lụng lụp lụt lủ lủi lủm lủn lủng lứa lức lứt lừ lừa lừng lử lửa lửng lữ lữa lững lự lựa lực lựng lựu lỵ ma mai man mang manh mao mau may me mem men meo mi mia mim min minh miên miêu miến miếng miết miếu miền miều miễn miễu miện miệng miệt mo moay moi mom mon mong moóc mu mua mui mum mun mung muôi muôn muông muối muốn muống muốt muồi muỗi muỗm muỗng muội muộn mà mài màn màng mành mào màu mày má mác mách mái mán máng mánh máo mát máu máy mâm mân mâng mâu mây mã mãi mãn mãng mãnh mão mè mèm mèn mèng mèo mé mém mén méo mép mét mê mên mênh mì mìn mình mí mía mích mím míp mít míu mò mòi mòm mòn mòng mó móc mói móm món móng móp mót mô môi môm môn mông mõ mõm mù mùa mùi mùn mùng mú múa múc múi múm mún múp mút măm măn măng mĩ mĩm mũ mũi mũm mơ mơi mơn mưa mưu mươi mương mướn mướp mướt mười mường mượn mượt mạ mạc mạch mại mạn mạng mạnh mạo mạp mạt mạy mả mải mảng mảnh mảy mấn mấp mất mấu mấy mầm mần mầng mầu mẩm mẩn mẩy mẫm mẫn mẫu mận mập mật mậu mắc mắm mắn mắng mắt mằn mẳn mặc mặn mặt mẹ mẹo mẹp mẹt mẻ mẻo mẽ mế mếch mến mếu mề mềm mền mễ mệ mệnh mệt mỉ mỉa mỉm mị mịch mịn mịnh mịt mọc mọi mọn mọng mọt mỏ mỏi mỏm mỏng mố mốc mối mống mốt mồ mồi mồm mồn mồng mổ mổng mỗ mỗi mộ mộc mộng một mớ mới mớm mớp mờ mời mờm mở mởn mỡ mợ mụ mục mụi mụn mụp mủ mủi mủm mủn mủng mứa mức mứt mứu mừng mửa mự mựa mực mỹ na nai nam nan nang nanh nao nau nay ne nem nen neo nga ngai ngam ngan ngang ngao ngau ngay nghe nghi nghinh nghiu nghiêm nghiên nghiêng nghiêu nghiến nghiền nghiễm nghiệm nghiện nghiệp nghiệt nghè nghèn nghèo nghé nghén nghét nghê nghênh nghêu nghì nghìn nghí nghít nghĩ nghĩa nghẹn nghẹo nghẹt nghẻo nghẽn nghẽo nghếch nghề nghều nghển nghểnh nghễ nghễnh nghễu nghệ nghệch nghện nghỉ nghỉm nghỉn nghỉnh nghỉu nghị nghịch nghịt nghịu ngoa ngoan ngoang ngoao ngoay ngoe ngoi ngon ngong ngoài ngoàm ngoác ngoách ngoái ngoáo ngoáy ngoã ngoãn ngoèo ngoé ngoéo ngoét ngoại ngoạm ngoạn ngoải ngoảng ngoảnh ngoảy ngoắc ngoắt ngoằn ngoằng ngoẵng ngoặc ngoặt ngoẻn ngu nguy nguyên nguyền nguyện nguyệt nguýt nguẩy nguồi nguồn nguội nguỵ nguỷu ngà ngài ngàm ngàn ngàng ngành ngào ngàu ngày ngác ngách ngái ngám ngán ngáng ngáo ngáp ngát ngáu ngáy ngâm ngân ngâu ngây ngã ngãi ngãng ngão ngò ngòi ngòm ngòn ngòng ngó ngóc ngói ngóm ngón ngóng ngóp ngót ngô ngôi ngôn ngông ngõ ngõi ngõng ngùi ngùng ngú ngúc ngúng ngút ngăm ngăn ngũ ngơ ngơi ngơm ngơn ngư ngưa ngưng ngưu ngươi ngước người ngường ngưởng ngưỡng ngược ngượng ngạc ngạch ngại ngạn ngạnh ngạo ngạt ngả ngải ngảnh ngấc ngấm ngấn ngấp ngất ngấu ngấy ngầm ngần ngầu ngầy ngẩm ngẩn ngẩng ngẫm ngẫn ngẫu ngậm ngận ngập ngật ngậu ngậy ngắc ngắm ngắn ngắt ngằn ngẳng ngẵng ngặt ngọ ngọc ngọn ngọng ngọt ngỏ ngỏm ngỏn ngỏng ngố ngốc ngốn ngốt ngồi ngồm ngồn ngồng ngổ ngổm ngổn ngỗ ngỗng ngộ ngộc ngộn ngột ngớ ngớn ngớp ngớt ngờ ngời ngờm ngỡ ngợ ngợi ngợm ngợp ngụ ngụa ngục ngụm ngụp ngủ ngủi ngủn ngứ ngứa ngứt ngừ ngừa ngừng ngửa ngửi ngửng ngữ ngự ngựa ngực nha nhai nham nhan nhang nhanh nhao nhau nhay nhe nhem nhen nheo nhi nhinh nhiu nhiên nhiêu nhiếc nhiếp nhiều nhiễm nhiễn nhiễu nhiệm nhiệt nho nhoai nhoang nhoay nhoe nhoen nhoi nhom nhong nhoà nhoài nhoàm nhoá nhoáng nhoáy nhoè nhoèn nhoé nhoét nhoạng nhoẹt nhoẻn nhu nhui nhung nhuyễn nhuôm nhuần nhuận nhuế nhuệ nhuốc nhuốm nhuộm nhuỵ nhà nhài nhàm nhàn nhàng nhành nhào nhàu nhày nhá nhác nhách nhái nhám nháng nhánh nháo nháp nhát nháy nhâm nhân nhâng nhâu nhây nhã nhãi nhãn nhãng nhão nhè nhèm nhèo nhé nhén nhéo nhép nhét nhênh nhì nhìn nhí nhía nhích nhím nhín nhíp nhít nhíu nhò nhòm nhó nhóc nhói nhóm nhón nhóng nhóp nhót nhô nhôi nhôm nhôn nhông nhõ nhõm nhõn nhù nhùi nhùn nhùng nhú nhúa nhúc nhúm nhún nhúng nhút nhăm nhăn nhăng nhĩ nhũ nhũn nhũng nhơ nhơi nhơm nhơn như nhưng nhương nhướng nhường nhưỡng nhược nhượng nhạc nhạn nhạnh nhạo nhạp nhạt nhạy nhả nhải nhảm nhản nhảnh nhảu nhảy nhấc nhấm nhấn nhấp nhất nhầm nhần nhầy nhẩm nhẫn nhẫy nhậm nhận nhập nhật nhậu nhậy nhắc nhắm nhắn nhắng nhắp nhắt nhằm nhằn nhằng nhẳn nhẳng nhẵn nhẵng nhặm nhặn nhặng nhặt nhẹ nhẹm nhẹn nhẹo nhẹp nhẹt nhẻ nhẻm nhẽ nhẽo nhện nhệu nhỉ nhỉnh nhị nhịn nhịp nhịt nhịu nhọ nhọc nhọn nhọt nhỏ nhỏm nhỏng nhố nhốc nhối nhốn nhốt nhồi nhồm nhồn nhồng nhổ nhổm nhổn nhộn nhộng nhột nhớ nhớm nhớn nhớp nhớt nhờ nhời nhờn nhở nhởn nhỡ nhợ nhợt nhụ nhụa nhục nhụi nhụng nhụt nhủ nhủi nhủn nhứ nhức nhứt nhừ nhử nhửng những nhự nhựa nhựt ni nia nin ninh niu niêm niên niêu niết niềm niền niềng niễng niệm niệt niệu no noa noi nom non nong noãn nua nung nuôi nuông nuốc nuối nuốm nuốt nuộc nuột nà nài nàn nàng nành nào này ná nác nách nái nám nán náng nánh náo nát náu náy nân nâng nâu nây nã não nãy nè nèo né ném nén néo nép nét nê nêm nên nêu nì nình ních nín nính níp nít níu nò nòi nó nóc nói nón nóng nót nô nôi nôm nôn nông nõ nõn nùi nùn nùng núc núi núm núng núp nút năm năn năng nĩa nũng nơ nơi nơm nư nưa nưng nương nước nướng nườm nường nược nượp nạ nạc nại nạm nạn nạng nạnh nạo nạp nạt nạy nả nải nản nảy nấc nấm nấng nấp nấu nấy nầm nần nầy nẩy nẫng nẫu nậm nậng nập nậu nậy nắc nắm nắn nắng nắp nằm nằn nằng nặc nặn nặng nẹp nẹt nẻ nẻo nếm nến nếp nết nếu nề nền nể nệ nệm nện nỉ nịch nịnh nịt nịu nọ nọc nọn nọng nọt nỏ nỏi nố nốc nối nống nốt nồ nồi nồm nồng nổ nổi nỗ nỗi nỗng nộ nội nộm nộn nộp nột nớ nới nớp nớt nờ nờm nở nỡ nỡm nợ nợp nụ nục nủa nứa nức nứt nừng nửa nữ nữa nự nực nựng o oa oai oan oang oanh oe oi om ong oà oàm oàng oành oác oách oái oán oát oé oăm oăng oạch oại oạp oải oản oắt oằn oẳn oẳng oặt oẹ oẻ pa pan pao pe pha phai phang phanh phao phau phay phe phen pheo phi phim phin phinh phiu phiên phiêu phiếm phiến phiết phiếu phiền phiện phiệt pho phoi phom phong phu phui phun phung phuy phà phàm phàn phàng phành phào phá phác phách phái phán pháo pháp phát phân phây phè phèn phèng phèo phéng phép phét phê phên phì phìa phình phí phía phích phím phính phò phòi phòng phó phóc phóng phót phô phôi phôm phông phù phùn phùng phú phúc phún phúng phút phăm phăn phăng phĩnh phũ phơ phơi phơn phưng phương phước phướn phướng phường phưỡn phượng phượu phạch phạm phạn phạng phạt phả phải phản phảng phảy phấn phấp phất phầm phần phẩm phẩn phẩy phẫn phẫu phận phập phật phắc phắn phắp phắt phẳng phẹt phế phếch phết phề phềnh phều phễn phễu phệ phệnh phệt phỉ phỉnh phị phịa phịch phịt phịu phọng phọt phỏng phố phốc phối phốp phồ phồm phồn phồng phổ phổi phổng phỗng phộng phới phớt phờ phở phỡn phụ phục phụng phụt phủ phủi phứa phức phứt phừng phựa phựt pi pin pom pu pác páp pê pô pông pơ qua quai quan quang quanh quao quau quay que quen queo quoàng quoạng quoắt quy quyên quyến quyết quyền quyển quyện quyệt quà quài quàn quàng quành quào quàu quày quá quác quách quái quán quáng quánh quáo quát quáu quân quây quãng què quèn quèo qué quén quéo quét quê quên quít quý quýnh quýt quăm quăn quăng quơ quạ quạc quạch quại quạng quạnh quạt quạu quạy quả quải quản quảng quảy quấc quấn quất quấy quần quầng quầy quẩn quẩng quẩy quẫn quẫy quận quật quậy quắc quắm quắn quắp quắt quằn quẳm quẳng quặc quặm quặn quặng quặp quặt quẹo quẹt quẻ quẽ quế quết quếu quềnh quều quệ quệch quện quệnh quệt quịt quốc quớ quờ quở quỳ quỳnh quỵ quỵt quỷ quỷnh quỹ ra rai ram ran rang ranh rao rau ray re ren reng reo ri ria rim rin rinh riu riêng riêu riết riếu riềm riềng riệt ro roa roi rom rong ru rua rum run rung ruốc ruối ruồi ruồng ruổi ruỗng ruộm ruộng ruột rà rài ràn ràng rành rào rày rá rác rách rái rám rán ráng ráo ráp rát ráy râm rân râu rây rã rãi rãnh rão rãy rè rèm rèn rèo ré rén réo rét rê rên rêu rì rìa rình rìu rí rích rít ríu rò ròi ròm ròng ró róc rói róm rón róng rót rô rôm rông rõ rõi rù rùa rùm rùn rùng rú rúc rúi rúm rún rúng rúp rút răm răn răng rĩ rũ rũa rơ rơi rơm rơn rư rưa rưng rươi rươm rương rước rưới rướm rướn rười rườm rườn rường rưởi rưỡi rượi rượn rượt rượu rạ rạc rạch rạn rạng rạo rạp rạt rạy rả rải rảnh rảo rảy rấm rấn rấp rất rầm rần rầu rầy rẩm rẩy rẫm rẫy rậm rận rập rật rắc rắm rắn rắp rắt rằm rằn rằng rặng rặt rẹo rẹt rẻ rẻng rẻo rẽ rế rếch rến rếp rết rề rền rều rể rểnh rễ rệ rệch rện rệp rệt rệu rỉ rỉa rỉnh rịa rịch rịn rịt rọ rọc rọi rọm rọt rỏ rỏm rỏn rốc rối rốn rống rốp rốt rồ rồi rồm rồng rổ rổi rổng rỗ rỗi rỗng rộ rộc rộm rộn rộng rộp rớ rớm rớt rờ rời rờm rờn rở rởm rởn rỡ rỡn rợ rợi rợm rợn rợp rợt rục rụi rụng rụt rủ rủa rủi rủn rủng rứa rức rứt rừng rửa rửng rữa rựa rực sa sai sam san sang sanh sao sau say se sen seo si sim sin sinh siu siêng siêu siết siểm siểng siễn so soa soi son song soong soà soài soái soán soát soóc soạn soạng soạt su sui sum sun sung suy suyển suyễn suê suôn suông suý suýt suất suối suốt suồng suỵt sà sài sàm sàn sàng sành sào sá sác sách sái sám sán sáng sánh sáo sáp sát sáu sâm sân sâu sây sã sãi sè sèo séc sém sét sê sên sênh sêu sì sình sính sít sò sòi sòm sòng sóc sói sóm són sóng sót sô sôi sông sõi sõng sù sùi sùm sùng sú súc sún súng súp sút săm săn săng sĩ sũng sơ sơm sơn sư sưa sưng sưu sương sướng sướt sườn sường sưởi sượng sượt sạ sạch sạm sạn sạo sạp sạt sả sải sản sảng sảnh sảo sảy sấm sấn sấp sất sấu sấy sầm sần sầu sầy sẩm sẩn sẩy sẫm sậm sập sật sậu sậy sắc sắm sắn sắng sắp sắt sằng sẵn sặc sặm sặt sẹ sẹm sẹo sẻ sẻn sẽ sến sếp sếu sề sền sể sểnh sễ sệ sệt sỉ sỉa sỉnh sị sịa sịch sịt sọ sọc sọm sọt sỏ sỏi số sốc sống sốp sốt sồ sồi sồn sồng sổ sổi sổng sỗ sộ sộp sột sớ sới sớm sớn sớt sờ sờm sờn sở sởi sởn sỡ sợ sợi sụ sụa sục sụm sụn sụp sụt sủa sủi sủng sứ sứa sức sứt sừn sừng sử sửa sửng sửu sữa sững sự sực sựng sựt ta tai tam tan tang tanh tao tay te tem ten teng teo tha thai tham than thang thanh thao thau thay the then theo thi thia thin thinh thiu thiêm thiên thiêng thiêu thiếc thiến thiếp thiết thiếu thiềm thiền thiềng thiều thiểm thiển thiểu thiện thiệp thiệt thiệu tho thoa thoai thoang thoi thom thon thong thoà thoàn thoá thoái thoán thoáng thoát thoăn thoại thoạt thoả thoải thoảng thoắng thoắt thu thua thui thum thun thung thuyên thuyết thuyền thuê thuôn thuý thuần thuẫn thuận thuật thuế thuể thuốc thuốn thuồn thuồng thuổng thuỗn thuộc thuộm thuỳ thuỵ thuỷ thà thài thàm thành thào thày thá thác thách thái thám thán tháng thánh tháo tháp tháu tháy thâm thân thâu thây thãi thè thèm thèn thèo thé thép thét thê thêm thênh thêu thì thìa thìn thình thìu thí thía thích thím thín thính thíp thít thò thòi thòm thòng thó thóc thói thóp thót thô thôi thôn thông thõng thù thùa thùi thùm thùng thú thúc thúi thúng thút thăm thăn thăng thũng thơ thơi thơm thơn thư thưa thưng thương thước thướt thườn thường thưởng thưỡi thưỡn thược thượng thượt thạc thạch thạnh thạo thạp thả thải thảm thản thảng thảnh thảo thảy thấm thấp thất thấu thấy thầm thần thầu thầy thẩm thẩn thẩu thẫm thẫn thậm thận thập thật thắc thắm thắn thắng thắp thắt thằn thằng thẳm thẳng thặng thẹn thẹo thẹp thẻ thẻo thẽ thế thếch thếp thết thề thềm thều thể thểu thệ thện thỉ thỉnh thỉu thị thịch thịnh thịt thịu thọ thọc thọt thỏ thỏi thỏm thố thốc thối thốn thống thốt thồ thồi thồm thồn thổ thổi thổn thộc thộn thộp thớ thớt thờ thời thờn thở thợ thợt thụ thục thụi thụng thụp thụt thủ thủa thủi thủm thủng thứ thức thừ thừa thừng thử thửa thững thự thực ti tia tim tin tinh tiu tiêm tiên tiêng tiêu tiếc tiếm tiến tiếng tiếp tiết tiếu tiềm tiền tiều tiểu tiễn tiễu tiệc tiệm tiện tiệp tiệt to toa toan toang toanh toe toen toi tom ton tong toong toà toài toàn toàng toác toái toán toáng toát toáy toè toèn toé toét toòng toạ toạc toại toả toản toẹt toẻ toẽ tra trai tram tran trang tranh trao trau tre treo tri trinh triêng triêu triến triết triền triềng triều triển triện triệng triệt triệu tro troi tron trong tru trui trun trung truy truyền truyện truân truông truất truật truồng truột truỵ trà trài tràm tràn tràng trành trào tràu trày trá trác trách trái trám trán tráng tránh tráo tráp trát trâm trân trâng trâu trây trã trãi trè trèm trèn trèo trém tréo trét trê trên trêu trì trình trìu trí trích trít trò tròi tròm tròn tròng tróc trói tróm tróng trót trô trôi trôm trôn trông trõm trõn trù trùi trùm trùn trùng trú trúc trúm trúng trút trăm trăn trăng trĩ trĩnh trĩu trũi trũng trơ trơi trơn trưa trưng trương trước trướng trườn trường trưởng trưỡng trượng trượt trạc trạch trại trạm trạng trạo trạy trả trải trảm trảng trảo trảu trảy trấn trấp trấu trầm trần trầu trầy trẩn trẩu trẩy trẫm trậm trận trập trật trắc trắm trắng trắt trằm trằn trặc trặn trẹ trẹo trẹt trẻ trẻo trẽ trẽn trếch trết trề trễ trệ trệch trệt trệu trỉa trị trịa trịch trịnh trịt trọ trọc trọi trọn trọng trọt trỏ trỏi trỏng trố trốc trối trốn trống trồ trồi trồng trổ trổi trổng trỗ trộ trộc trội trộm trộn trớ trớn trớp trớt trờ trời trờn trở trợ trợn trợt trụ trụa trục trụi trụm trụn trụng trụp trụt trủ trứ trứng trừ trừa trừng trửng trữ trự trực tu tua tui tum tun tung tuy tuyn tuyên tuyến tuyết tuyền tuyển tuyệt tuân tuôn tuông tuý tuấn tuất tuần tuế tuếch tuệ tuệch tuốt tuồn tuồng tuổi tuộc tuột tuỳ tuỵ tuỷ ty tà tài tàn tàng tành tào tàu tày tá tác tách tái tám tán táng tánh táo táp tát táu táy tâm tân tâng tâu tây tã tãi tè tèm tèn tèo té téc tém tép tét tê têm tên tênh têu tì tìm tình tí tía tích tím tín tính típ tít tíu tò tòi tòm tòn tòng tó tóc tói tóm tóp tót tô tôi tôm tôn tông tõm tù tùm tùng tú túc túi túm túng túp tút tăm tăn tăng tĩ tĩnh tĩu tũm tơ tơi tư tưa tưng tươi tươm tương tước tưới tướn tướng tướp tướt tườm tường tườu tưởi tưởng tược tượng tượp tượt tạ tạc tạch tại tạm tạng tạnh tạo tạp tạt tả tải tản tảng tảo tấc tấm tấn tấp tất tấu tấy tầm tần tầng tầy tẩm tẩn tẩu tẩy tận tập tật tậu tắc tắm tắn tắp tắt tằm tằn tằng tẳn tặc tặn tặng tẹo tẹp tẹt tẻ tẻm tẻo tẽ tẽn tế tếch tết tếu tề tềnh tể tểnh tễ tễnh tệ tệp tỉ tỉa tỉm tỉnh tị tịch tịnh tịt tịu tọc tọng tọp tọt tỏ tỏi tỏm tỏng tố tốc tối tốn tống tốp tốt tồ tồi tồn tồng tổ tổn tổng tộ tộc tội tột tớ tới tớn tớp tớt tờ tời tởm tợ tợn tợp tụ tục tụi tụm tụng tụt tủ tủa tủi tủm tủn tứ tứa tức từ từng tử tửa tửng tửu tự tựa tựu tỵ tỷ u um un ung uy uyên uyển uôm uý uất uẩn uẩy uế uể uốn uống uổng uột uỳnh uỵch uỷ va vai van vang vanh vao vay ve ven veo vi vinh viêm viên viếng viết viền viển viễn việc viện việt vo voan voi von vong vu vua vui vun vung vuông vuốt vuột và vài vàm vàn vàng vành vào vày vá vác vách vái ván váng vánh váo váp vát váy vâm vân vâng vây vã vãi vãn vãng vãnh vè vèo vé véc vén véo vét vê vên vênh vêu vì ví vía vích vít víu vò vòi vòm vòn vòng vó vóc vói vón vóng vót vô vôi vôn vông võ võng vù vùa vùi vùn vùng vú vúc vút văn văng vĩ vĩnh vũ vũm vũng vơ vơi vưng vưu vươn vương vướng vườn vưởng vược vượn vượng vượt vạ vạc vạch vại vạm vạn vạng vạnh vạp vạt vạy vả vải vảng vảy vấn vấp vất vấu vấy vần vầng vầu vầy vẩn vẩu vẩy vẫn vẫy vậm vận vập vật vậy vắc vắn vắng vắt vằm vằn vằng vẳng vặc vặn vặt vẹm vẹn vẹo vẹt vẻ vẻn vẻo vẽ vế vếch vết vếu về vền vều vểnh vệ vện vệt vỉ vỉa vị vịm vịn vịnh vịt vọ vọc vọi vọng vọp vọt vỏ vỏn vỏng vố vốc vối vốn vống vồ vồi vồn vồng vổ vổng vỗ vội vớ với vớt vờ vời vờn vở vởn vỡ vợ vợi vợt vụ vục vụn vụng vụt vức vứt vừa vừng vửng vữa vững vựa vực vựng xa xam xan xang xanh xao xay xe xem xen xeo xi xia xim xin xinh xiêm xiên xiêu xiếc xiết xiềng xiểm xiển xiểng xo xoa xoan xoang xoay xoe xoen xoi xom xon xong xoong xoà xoài xoàm xoàn xoàng xoành xoá xoác xoát xoáy xoã xoè xoèn xoét xoăn xoạc xoạch xoạng xoả xoải xoảng xoắn xoẹ xoẹt xu xua xui xum xung xuy xuya xuynh xuyên xuyến xuyết xuân xuây xuê xuôi xuý xuýt xuất xuẩn xuề xuềnh xuể xuệch xuống xuồng xuổng xuỳ xuỵt xà xài xàm xàng xành xào xàu xá xác xách xái xám xán xáo xáp xát xáy xâm xâu xây xã xè xèn xèng xèo xé xéc xén xéo xép xét xê xên xênh xêu xì xình xìu xí xía xích xính xít xíu xòm xòng xó xóc xói xóm xón xóp xót xô xôi xôm xôn xông xõm xõng xù xùi xùm xùng xú xúc xúi xúm xúng xúp xút xăm xăn xăng xĩnh xũ xơ xơi xơm xơn xưa xưng xương xước xướng xười xưởng xược xạ xạc xạch xạo xạp xạu xả xảm xảnh xảo xảu xảy xấc xấp xấu xầm xẩm xẩn xẩu xẩy xập xắc xắm xắn xắp xằng xẵng xẹc xẹo xẹp xẹt xẻ xẻn xẻng xẻo xẽo xế xếch xếp xềm xềnh xều xể xệ xệch xệp xệu xỉ xỉa xỉn xỉnh xỉu xị xịch xịt xịu xọ xọc xọp xỏ xỏng xố xốc xối xốn xống xốp xốt xồ xồm xồn xồng xổ xổi xổm xổng xộc xộn xộp xớ xới xớp xớt xờ xờm xở xởi xởn xỡ xợp xợt xụ xục xụi xụp xủng xứ xức xứng xừ xử xửa xửng xực y yên yêng yêu yếm yến yết yếu yểm yểng yểu à ào á ác ách ái ám án áng ánh áo áp át áy âm ân âu ã è èo é éc ém én éo ép ét ê êm êu ì ìn ình í ích ín ít ò òi òm òng ó óc ói óng óp ót ô ôi ôm ôn ông ù ùa ùm ùn ùng ú úa úi úm úng úp út ý ăm ăn ăng đa đai đam đan đang đanh đao đau đay đe đem đen đeo đi đin đinh điên điêu điếc điếm điếng điếu điền điều điểm điển điểu điệm điện điệp điệu đo đoan đoi đom đon đong đoài đoàn đoàng đoành đoá đoái đoán đoãng đoạ đoạn đoạt đoản đoảng đu đua đui đum đun đung đuôi đuốc đuối đuổi đuỗn đuột đà đài đàm đàn đàng đành đào đày đá đác đách đái đám đán đáng đánh đáo đáp đát đáy đâm đâu đây đã đãi đãng đãy đè đèm đèn đèo đéc đéo đét đê đêm đên đênh đêu đì đìa đình đìu đía đích đính đít đò đòi đòm đòn đòng đó đóc đói đóm đón đóng đót đô đôi đôm đôn đông đõ đù đùa đùi đùm đùn đùng đú đúc đúm đún đúng đúp đút đăm đăng đĩ đĩa đĩnh đũa đũng đơ đơm đơn đưa đưng đương đước đười đườn đường đưỡn được đượm đạc đạch đại đạm đạn đạo đạp đạt đả đảm đản đảng đảo đảy đấm đấng đất đấu đấy đầm đần đầu đầy đẩu đẩy đẫm đẫn đẫy đậm đận đập đật đậu đậy đắc đắm đắn đắng đắp đắt đằm đằn đằng đẳng đẵm đẵn đẵng đặc đặn đặng đặt đẹn đẹp đẹt đẻ đẽ đẽo đế đếch đếm đến đề đềm đền đềnh đều để đểnh đểu đễ đễnh đệ đệm đệp đỉa đỉnh địa địch định địt địu đọ đọc đọi đọn đọng đọp đọt đỏ đỏi đỏm đố đốc đối đốm đốn đống đốp đốt đồ đồi đồm đồn đồng đổ đổi đổng đỗ đỗi độ độc đội độn động độp đột đớ đới đớn đớp đớt đờ đời đờm đờn đởm đởn đỡ đợ đợi đợp đợt đụ đục đụn đụng đụp đụt đủ đủi đủng đứ đứa đức đứng đứt đừ đừa đừng đử đực đựng ĩ ĩnh ơ ơi ơn ư ưa ưng ưu ươi ươm ươn ương ước ướm ướp ướt ườn ưỡn ạ ạch ạnh ạo ạt ả ải ảm ảng ảnh ảo ấm ấn ấp ất ấu ấy ầm ầy ẩm ẩn ẩu ẩy ậc ậm ập ắc ắng ắp ắt ằng ẳng ẵm ặc ặp ẹ ẹo ẹp ẹt ẻn ẻo ẽo ế ếch ếm ề ềnh ễnh ệ ệch ện ệnh ỉ ỉa ỉm ỉn ỉu ị ịch ịt ọ ọc ọi ọp ọt ỏi ỏm ỏn ỏng ố ốc ối ốm ống ốp ốt ồ ồm ồn ồng ổ ổi ổn ổng ộ ộc ộn ộp ớ ới ớm ớn ớt ờ ờn ở ỡm ợ ợt ụ ụa ục ụp ụt ủ ủa ủi ủn ủng ứ ứa ức ứng ừ ừng ửng ựa ực ỷ";

    var buffer: [15]u8 = undefined;
    const buff = buffer[0..];

    var it = std.mem.split(u8, words_str, " ");
    var syll: parsers.Syllable = undefined;
    var syllId: parsers.Syllable.UniqueId = undefined;
    var revertedSyll: parsers.Syllable = undefined;

    while (it.next()) |am_tiet| {
        std.debug.print("\nam_tiet: {s}\n", .{am_tiet});
        syll = parsers.parseAmTietToGetSyllable(true, std.debug.print, am_tiet);
        // syll = parsers.parseAmTietToGetSyllable(true, print, am_tiet);
        try expect(syll.can_be_vietnamese);
        try std.testing.expectEqualStrings(syll.printBuffUtf8(buff), am_tiet);

        syllId = syll.toId();
        revertedSyll = parsers.Syllable.newFromId(syllId);
        try std.testing.expectEqualStrings(revertedSyll.printBuffUtf8(buff), am_tiet);
    }
}
