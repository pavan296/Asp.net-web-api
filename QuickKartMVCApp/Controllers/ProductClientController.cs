using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using QuickKartMVCApp.Repository;
using System;
using System.Collections.Generic;
using System.Net.Http;

namespace QuickKartMVCApp.Controllers
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
                return View("Error");
            }
        }

        // GET: ProductClientController/Details/5
        public ActionResult Details(int id)
        {
            return View();
        }

        // GET: ProductClientController/Create
        public ActionResult Create()
        {
            return View();
        }

        // POST: ProductClientController/Create
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Create(IFormCollection collection)
        {
            try
            {
                return RedirectToAction(nameof(Index));
            }
            catch
            {
                return View();
            }
        }

        // GET: ProductClientController/Edit/5
        public ActionResult Edit(int id)
        {
            return View();
        }

        // POST: ProductClientController/Edit/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Edit(int id, IFormCollection collection)
        {
            try
            {
                return RedirectToAction(nameof(Index));
            }
            catch
            {
                return View();
            }
        }

        // GET: ProductClientController/Delete/5
        public ActionResult Delete(int id)
        {
            return View();
        }

        // POST: ProductClientController/Delete/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Delete(int id, IFormCollection collection)
        {
            try
            {
                return RedirectToAction(nameof(Index));
            }
            catch
            {
                return View();
            }
        }
    }
}
