using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using QuickKartMVC.Models;
using QuickKartMVC.Repository;
using System;
using System.Collections.Generic;
using System.Net.Http;

namespace QuickKartMVC.Controllers
{
    public class ProductClientController : Controller
    {
        IConfiguration configuration;
        public ProductClientController(IConfiguration configuration)
        {
            this.configuration = configuration;
        }
        // GET: ProductClientController
        public ActionResult Index()
        {

            try
            {
                ServiceRepository serviceRepository = new ServiceRepository(configuration);
                HttpResponseMessage response = serviceRepository.GetResponse("api/Product/");
                response.EnsureSuccessStatusCode();
                List<Models.Product> products = response.Content.ReadAsAsync<List<Models.Product>>().Result;
                return View(products);
            }
            catch (Exception ex)
            {
                return View();
            }
        }


        // GET: ProductClientController/Details/5
        public ActionResult Details(string productId)
        {
            try
            {
                ServiceRepository serviceRepository = new ServiceRepository(configuration);
                HttpResponseMessage response = serviceRepository.GetResponse("api/Product/GetProduct?productId=" + productId);
                response.EnsureSuccessStatusCode();
                Models.Product product = response.Content.ReadAsAsync<Models.Product>().Result;
                return View(product);
            }
            catch (Exception ex)
            {
                return View();
            }
        }

        // GET: ProductClientController/Create
        public ActionResult Create()
        {
            try
            {
                return View();
            }
            catch (Exception ex)
            {
                return View("Error");
            }
        }

        // POST: ProductClientController/Create
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Create(Models.Product prodObj)
        {
            try
            {
                ServiceRepository serviceRepository = new ServiceRepository(configuration);
                HttpResponseMessage response = serviceRepository.PostRequest("api/Product/AddProduct", prodObj);
                response.EnsureSuccessStatusCode();
                if (response.Content.ReadAsAsync<bool>().Result)
                    return View("Success");
                return View("Error");
            }
            catch (Exception ex)
            {
                return View("Error");
            }
        }


        public ActionResult Edit(Models.Product product)
        {
            try
            {
                return View(product);
            }
            catch (Exception ex)
            {
                return View("Error");
            }
        }


        // POST: ProductClientController/Edit/5
        public ActionResult UpdateProduct(Models.Product product)
        {
            try
            {
                ServiceRepository serviceRepository = new ServiceRepository(configuration);
                HttpResponseMessage response = serviceRepository.PutRequest("api/Product/UpdateProduct", product);
                response.EnsureSuccessStatusCode();
                if (response.Content.ReadAsAsync<bool>().Result)
                    return View("Success");
                return View("Error");
            }
            catch (Exception ex)
            {
                return View();
            }
        }


        public ActionResult Delete(Models.Product product)
        {
            try
            {
                return View(product);
            }
            catch (Exception ex)
            {
                return View("Error");
            }
        }


        // POST: ProductClientController/Delete/5
        public ActionResult DeleteProduct(Models.Product product)
        {
            try
            {
                ServiceRepository serviceRepository = new ServiceRepository(configuration);
                HttpResponseMessage response = serviceRepository.DeleteRequest("api/Product/DeleteProduct?ProductId=" + product.ProductId);
                response.EnsureSuccessStatusCode();
                if (response.Content.ReadAsAsync<bool>().Result)
                    return View("Success");
                return View("Error");
            }
            catch (Exception ex)
            {
                return View();
            }
        }

    }
}
