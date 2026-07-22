from playwright.sync_api import sync_playwright
import pathlib
url = "file://" + str(pathlib.Path("index.html").resolve())
with sync_playwright() as p:
    b = p.chromium.launch()
    pg = b.new_page(viewport={"width":1280,"height":900})
    pg.goto(url); pg.wait_for_timeout(800)
    pg.evaluate("document.getElementById('gallery').scrollIntoView()"); pg.wait_for_timeout(500)
    for _ in range(15):
        pg.evaluate("window.scrollBy(0,400)"); pg.wait_for_timeout(90)
    pg.wait_for_timeout(800)
    loaded = pg.eval_on_selector_all("#galleryGrid img","els=>els.filter(e=>e.complete&&e.naturalWidth>0).length")
    broken = pg.eval_on_selector_all("#galleryGrid img","els=>els.filter(e=>e.complete&&e.naturalWidth===0).map(e=>e.getAttribute('src')).slice(0,6)")
    print("loaded after scroll:", loaded, "/ 35")
    print("broken (first 6):", broken)
    b.close()
