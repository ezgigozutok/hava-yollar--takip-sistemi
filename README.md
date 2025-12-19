# Hava Yolları Takip Sistemi
Bir havayolu operasyonunu uçtan uca izlemek için tasarlanmış ilişkisel veritabanıdır. Sistem; uçuş planlamayı, yolcu rezervasyon ve bilet süreçlerini, koltuk atamalarını, mürettebat görev dağılımını, bagaj takibini, ödeme kayıtlarını ve uçak bakım geçmişini merkezi olarak yönetir. Microsoft SQL Server üzerinde tasarlanmıştır.
## Tablolar Arası İlişkiler

| İlişki | Türü | Açıklama |
|------|------|---------|
| Airline → Airplane | 1 → N | Bir havayolunun birden fazla uçağı olabilir. |
| Airplane → Flight | 1 → N | Bir uçak farklı zamanlarda birçok uçuş gerçekleştirebilir. |
| Flight → Ticket | 1 → N | Her uçuşta birden fazla bilet satılabilir. |
| Passenger → Ticket | 1 → N | Bir yolcu birden fazla bilet satın alabilir. |
| Airline → Crew | 1 → N | Bir havayolunun birçok mürettebatı bulunur. |
| Flight → Crew | N → N | Bir uçuşta birden fazla mürettebat görev alabilir, bir mürettebat birden fazla uçuşta görev alabilir. |
| Airplane → Seat | 1 → N | Her uçakta birden fazla koltuk bulunur. |
| Passenger → Reservation | 1 → N | Bir yolcu birden fazla rezervasyon yapabilir. |
| Flight → Reservation | 1 → N | Bir uçuş için birden fazla rezervasyon oluşturulabilir. |
| Ticket → Payment | 1 → N | Bir bilet için bir veya birden fazla ödeme kaydı bulunabilir. |
| Ticket → Baggage | 1 → N | Bir bilete birden fazla bagaj kaydı eklenebilir. |
| Flight → Flight_Status | 1 → N | Bir uçuşun zaman içerisinde birden fazla durum kaydı olabilir. |
| Airplane → Maintenance | 1 → N | Bir uçak için birden fazla bakım kaydı tutulabilir. |
| Member → Ticket | 1 → N | Bir üye birden fazla bilet satın alabilir. |
| FarePackage → Ticket | 1 → N | Aynı paket türü birden fazla bilette kullanılabilir. |
| FarePackage → FareRefundRules | 1 → N | Her paket için birden fazla iade kuralı tanımlanabilir. |
| Ticket → CheckIn | 1 → 1 | Her bilet için yalnızca bir online check-in yapılabilir. |
| Ticket → BoardingPass | 1 → 1 | Her bilet için tek bir biniş kartı üretilir. |
