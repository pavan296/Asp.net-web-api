using System;
using System.Collections.Generic;

namespace QuickKartDataAccessLayer.Models
{
    public partial class CardDetails
    {
        public decimal CardNumber { get; set; }
        public string NameOnCard { get; set; }
        public string CardType { get; set; }
        public decimal Cvvnumber { get; set; }
        public DateTime ExpiryDate { get; set; }
        public decimal? Balance { get; set; }
    }
}
