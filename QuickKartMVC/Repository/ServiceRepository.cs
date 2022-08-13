using Microsoft.Extensions.Configuration;
using System;
using System.Net.Http;

namespace QuickKartMVC.Repository
{
    public class ServiceRepository
    {
        private HttpClient Client { get; set; }
        public ServiceRepository(IConfiguration Configuration)
        {
            Client = new HttpClient();
            Client.BaseAddress = new Uri(Configuration.GetSection("ServiceUrl").Value.ToString());
        }
        public HttpResponseMessage GetResponse(string url)
        {
            return Client.GetAsync(url).Result;
        }
        public HttpResponseMessage PostRequest(string url, object model)
        {
            return Client.PostAsJsonAsync(url, model).Result;
        }
        public HttpResponseMessage PutRequest(string url, object model)
        {
            return Client.PutAsJsonAsync(url, model).Result;
        }
        public HttpResponseMessage DeleteRequest(string url)
        {
            return Client.DeleteAsync(url).Result;
        }

    }

}
