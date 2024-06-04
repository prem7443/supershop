from django.contrib import admin
from django.urls import path
from mainApp import views as mainApp
from django.conf import settings
from django.conf.urls.static import static
urlpatterns = [
    path('admin/', admin.site.urls),
    path('', mainApp.homePage,name="home"),
    path('about/', mainApp.aboutPage,name="about"),
    path('add-to-cart/', mainApp.addToCartPage,name="add-to-cart"),
    path('cart/', mainApp.cartPage,name="cart"),
    path('delete-cart/<str:id>/', mainApp.deleteCartPage,name="delete-cart"),
    path('update-cart/<str:id>/<str:op>/', mainApp.updateCartPage,name="update-cart"),
    path('checkout/', mainApp.checkoutPage,name="checkout"),
    path('re-payment/<int:id>/', mainApp.rePaymentPage,name="re-payment"),
    path('payment-success/<int:id>/<str:rppid>/<str:rpoid>/<str:rpsid>/', mainApp.paymentSuccessPage,name="payment-success"),
    path('confirmation/', mainApp.confirmationPage,name="confirmation"),
    path('contact/', mainApp.contactPage,name="contact"),
    path('login/', mainApp.loginPage,name="login"),
    path('signup/', mainApp.signupPage,name="signup"),
    path('logout/', mainApp.logoutPage,name="logout"),
    path('profile/', mainApp.profilePage,name="profile"),
    path('update-profile/', mainApp.updateProfilePage,name="update-profile"),
    path('shop/<str:mc>/<str:sc>/<str:br>/', mainApp.shopPage,name="shop"),
    path('single-product/<int:id>/', mainApp.singleProductPage,name="single-product"),
    path('add-to-wishlist/<int:id>/',mainApp.addToWishlistPage,name="add-to-wishlist"),
    path('delete-wishlist/<int:id>/',mainApp.deleteWishlistPage,name="delete-wishlist"),
    path('newslatter/subscribe/',mainApp.newslatterSubscribePage,name="newslatter-subscribe"),
    path('search/',mainApp.searchPage,name="search"),
    path('forget-password-1/',mainApp.forgetPassword1Page,name="forget-password-1"),
    path('forget-password-2/',mainApp.forgetPassword2Page,name="forget-password-2"),
    path('forget-password-3/',mainApp.forgetPassword3Page,name="forget-password-3"),
]+static(settings.MEDIA_URL,document_root=settings.MEDIA_ROOT)
