const paypal = require('@paypal/checkout-server-sdk');
const payPalClient = require('../Common/payPalClient');

/**
@author https://github.com/eodeluga
@class Creates an itemised order for use with the PayPal REST SDK
*/
module.exports = class PayPalOrder {

    /**@private private instance variables*/
    #order;
    #currency;
    #runningTotal;
    #floatToInt = (value) => parseInt(String(value).replace('.', ''));
    /**
     * 
     * @param {1} returnUrl URL to redirect to on successful placement order 
     * @param {2} cancelUrl URL to redirect to if the user cancels the transaction
     * @param {3} currency Currency of the entire order 
     * @param {4} brand Brand/company name to display at PayPal checkout
     */
    constructor(returnUrl, cancelUrl, currency, brand) {
        
        this.#runningTotal = 0;
        this.#currency = currency;
        // Define PayPal order boilerplate
        this.#order = {
            intent: "CAPTURE",
            application_context: {
                return_url: returnUrl,
                cancel_url: cancelUrl,
                brand_name: brand,
                user_action: "CONTINUE"
            },
            purchase_units: [{ 
                amount: {
                    currency_code: this.#currency,
                    value: 0.0,
                    breakdown: {
                        item_total: {
                          currency_code: this.#currency,
                          value: 0.0
                        }
                    }
                },
                items: [],
            }]
        };
    }

    /**
     * Add a new item to the order
     * @param {1} name Name of item
     * @param {2} description Description of item
     * @param {3} sku Stock Keeping Unit of item
     * @param {4} price Price of item
     * @param {5} quantity Quantity of item
     */
    addItem(name, description, sku, price, quantity) {
        
        this.#order["purchase_units"][0]["items"].push({
            name: name,
            description: description,
            sku: sku,
            unit_amount: {
                currency_code: this.#currency,
                value: price 
            },
            quantity: quantity
        });
        
        // Add item price multiplied by quantity to running total
        this.#runningTotal += this.#floatToInt(price) * quantity;
    }

    /**
     * @returns Returns a PayPal order object
     * */
    #getOrderRequest() {
        
        // Get the order running total start digits and last two digits
        let value = String(this.#runningTotal);
        let begin = value.slice(0, (value.length - 2));
        let end = value.slice((value.length - 2));
        
        // Create new string with floating point between both values
        let orderTotal = `${begin}.${end}`;
        
        // Insert final figure into PayPal order object
        this.#order['purchase_units'][0].amount.value = orderTotal;
        this.#order['purchase_units'][0].amount.breakdown.item_total.value = orderTotal;
        return this.#order;
    }

    async createOrder() {
        
        let orderRequest = this.#getOrderRequest();
        
        // Call PayPal to set up a transaction
        const request = new paypal.orders.OrdersCreateRequest();
        request.prefer("return=representation");
        request.requestBody(orderRequest);

        // Place the order
        let order;
        order = await payPalClient.client().execute(request);
        return order.result;
    }
}
